"""User model."""
import pytz
from django.conf import settings

# django
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.db.models import Avg
from django.utils import timezone
from timezone_field import TimeZoneField

from cores.models import CoreUser
from destinations.models import Destination
from users.managers import PasswordRecoveryManager
from utils.models import BaseCreatedUpdatedModel


class User(BaseCreatedUpdatedModel, AbstractUser):
    """User model.

    Extend from Django abstract user, change the username field to email.
    """

    email = models.EmailField(
        'email address',
        unique=True,
        error_messages={
            'unique': 'A user with that email already exist',
        },
    )

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['first_name', 'last_name', 'email']
    mantra = models.TextField(default=None, null=True)
    tz_zone = TimeZoneField(default=settings.TIME_ZONE)
    is_verified = models.BooleanField(default=False, help_text='set to true when address email have verified')

    def __str__(self):
        return self.username

    def get_short_name(self):
        return self.username

    def time_for_user(self, server_hour):
        """Return the timezone for the user."""
        return server_hour.astimezone(self.tz_zone)

    @property
    def has_device(self):
        """Returns if user has device."""
        return self.devices.exists()


class PasswordRecoveryCode(BaseCreatedUpdatedModel):

    user = models.ForeignKey('User', related_name='recovery_codes', on_delete=models.CASCADE)
    code = models.CharField('Recovery code', max_length=10)
    expiration = models.DateTimeField()
    used = models.BooleanField(default=False)

    objects = PasswordRecoveryManager()

    def __str__(self):
        return f'{self.user.email} | code: {self.code} | used: {self.used}'


class UserProfile(BaseCreatedUpdatedModel):
    """User profile model."""

    user = models.OneToOneField(User, on_delete=models.CASCADE, primary_key=True, related_name="user_profile")

    score = models.IntegerField(null=False, blank=False, default=0)
    credits = models.IntegerField(null=False, blank=False, default=0)

    core_cap = models.IntegerField(null=False, blank=False, default=0)  # Internal, use user_core_cap
    core_power_increase = models.IntegerField(null=False, blank=False, default=0)

    onboarding = models.BooleanField(default=False)
    quiz = models.BooleanField(default=False)
    days_in_journey = models.IntegerField(null=False, blank=False, default=0)
    in_journey = models.BooleanField(default=False)
    morning_check_time = models.TimeField(null=True, default='09:00:00')
    night_check_time = models.TimeField(null=True, default='21:00:00')
    night_checks_in_row = models.IntegerField(null=False, blank=False, default=0)
    last_night_check = models.DateField(null=True, default=None)

    pause = models.BooleanField(default=False)
    notifications = models.BooleanField(default=True)
    destination_index = models.IntegerField(default=1)  # Current destination index

    @property
    def get_main_device(self):
        """Returns main device object."""
        return self.user.devices.last()

    @property
    def momentum(self):
        from bonus.models import INCREMENT_VALUE, BonusUser
        from bonus.strings import (
            INCREASE_CORE_POWER_DAY,
            INCREASE_MOMENTUM_JOURNEY,
        )

        momentum = 0
        power_avg = CoreUser.objects.filter(user=self.user, enabled=True).aggregate(Avg('power'))["power__avg"]
        if power_avg is not None:
            momentum += power_avg

        # Bonus
        if BonusUser.objects.filter(
            user=self.user, bonus__name=INCREASE_CORE_POWER_DAY, active=True, date_active=timezone.now().date()
        ).exists():
            momentum += INCREMENT_VALUE
        if BonusUser.objects.filter(user=self.user, bonus__name=INCREASE_MOMENTUM_JOURNEY, active=True).exists():
            momentum += INCREMENT_VALUE

        return momentum

    @property
    def user_core_cap(self):
        """Returns the sum between the core_cap increase and the destination core cap"""
        try:
            destination = Destination.objects.get(index=self.destination_index)
        except Destination.DoesNotExist:
            destination = None
        return self.core_cap + destination.core_cap if destination else 0

    def get_actual_destination(self):
        """Returns current destination object."""
        return Destination.objects.filter(index=self.destination_index).first()

    def time_to_server(self, purpose, to_convert_datetime):
        """calculation of the distance between the user and the server for the purpose

        Args:
            purpose (string): choices into ['morning', 'night']

        Returns:
            [datetime]: time to server
        """
        server_timezone = pytz.timezone(settings.TIME_ZONE)
        time = getattr(self, f'{purpose}_check_time')
        # Build datetime from to convert datetime and time of purpose
        to_convert_datetime = to_convert_datetime.replace(
            hour=time.hour, minute=time.minute, second=time.second, tzinfo=self.user.tz_zone
        )
        return to_convert_datetime.astimezone(server_timezone)

    def get_next_destination(self):
        """Returns next destinastion object."""
        next_destination = Destination.objects.filter(index=self.destination_index + 1).first()
        if not next_destination:
            # Arrived at the last destination
            return Destination.objects.all().order_by('index').last()
        return next_destination

    @property
    def actual_destination(self):
        """Returns current destination name."""
        actual_destination = self.get_actual_destination()
        if actual_destination:
            return actual_destination.destination
        return self.next_destination

    @property
    def actual_destination_length(self):
        """Returns current destination length."""
        actual_destination = self.get_actual_destination()
        if actual_destination:
            return actual_destination.length
        return self.get_next_destination().length

    @property
    def next_destination(self):
        """Returns next destination name."""
        return self.get_next_destination().destination
