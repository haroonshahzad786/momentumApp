from math import ceil

from destinations.models import Destination, DestinationUser
from quests.commons import check_validation_quest
from users.commons import add_credits
from users.models import UserProfile


def night_check_journey(user):
    status = {"journey_ended": False, "journey_failed": False}
    user_profile = UserProfile.objects.get(user=user)
    next_destination = Destination.objects.filter(length=user_profile.destination_index + 1)
    user_profile.days_in_journey += 1
    # Checks if the user has at least the half journey completed to validate the momentum
    if user_profile.days_in_journey >= ceil(next_destination.length / 2):
        if user_profile.momentum >= next_destination.momentum_required:
            if user_profile.days_in_journey == next_destination.length:
                add_credits(user, multiplier=user_profile.days_in_journey, credits_number=50)
                user_profile.days_in_journey = 0
                current_destination_reached = Destination.objects.get(index=user_profile.destination_index)
                DestinationUser.objects.create(user=user, destination=current_destination_reached)
                user_profile.destination_index = current_destination_reached.index
                user_profile.core_cap = current_destination_reached.core_cap
                user_profile.in_journey = False
                user_profile.save()
                status["journey_ended"] = True
                status["journey_failed"] = False
        else:
            status["journey_ended"] = True
            status["journey_failed"] = True
    status["quest"] = check_validation_quest(user)
    return status
