"""User signals."""

from django.db.models import Q
from django.db.models.signals import post_save
from django.dispatch import receiver

from cockpit_list.models import CockpitList, CockpitListBase
from cores.models import CoreUser
from destinations.models import Destination, DestinationUser
from habits.models import Habits, HabitsBase
from improvements.models import Improvement, ImprovementUser
from mantras.models import Mantras
from users.models import User, UserProfile
from utils.general import CoresEnum


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created and not instance.is_superuser:
        # Habits
        for i in HabitsBase.objects.all():
            Habits.objects.create(
                user=instance, name=i.name, positive=i.positive, description=i.description, core=i.core
            )

        # Mantra
        if Mantras.objects.last():
            mantra_base = Mantras.objects.latest('pk')
            instance.mantra = mantra_base.text
            instance.save()

        # Cores
        for core in CoresEnum.choices():
            if core[1] == 'Mindset':
                CoreUser.objects.create(user=instance, core_string=core[0], enabled=True)
            else:
                CoreUser.objects.create(user=instance, core_string=core[0])
        UserProfile.objects.create(user=instance)

        # Destinations
        destination = Destination.objects.get(index=1)
        DestinationUser.objects.create(user=instance, destination=destination)

        # CockpitList
        for c in CockpitListBase.objects.all():
            CockpitList.objects.create(
                user=instance,
                name=c.name,
                description=c.description,
                enabled=c.enabled,
                category=c.category,
                destination=c.destination,
                options=c.options,
            )

        # Improvement
        improvements = Improvement.objects.filter(Q(default=True) | Q(destination=destination))
        for improvement in improvements:
            ImprovementUser.objects.create(user=instance, improvement=improvement)
