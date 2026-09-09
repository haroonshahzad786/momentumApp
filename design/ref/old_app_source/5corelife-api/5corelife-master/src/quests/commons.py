"""Quests commons."""

# Django REST Framework
import logging

from rest_framework import serializers

from cores.models import CoreUser

# 5Corelife
from quests.models import Quest, UserQuest
from users.commons import add_credits

logger = logging.getLogger(__name__)


def fragile_cargo(user):
    """
    Validates the completion of this quest. Calculates the range, and must not be greather than 20% from the lower
    power. Returns a boolean with the status result.

    Parameters:
    user (User): An user

    Returns:
    boolean: Success status of the mission
    """
    queryset = (
        CoreUser.objects.filter(user=user, enabled=True)
        .values_list("power", flat=True)
        .order_by("power")
    )
    # In percentage, the difference between the maximum and the minimum can't be greather than 0.2
    divisor = queryset.last()
    return (queryset.first() / divisor) > 0.2 if divisor > 0 else 0


def navigate_safely(user):
    """
    Validates the completion of this quest. Returns a boolean with the status result.
    To do so, checks if the power is greater (or at least, equal), than the previous day. This is done per core enabled.
    All enabled cores must be compliant to this constraint.

    Parameters:
    user (User): An user

    Returns:
    boolean: Success status of the quest
    """
    cores_powers = (
        CoreUser.objects.filter(user=user, enabled=True)
        .values_list("power", "power_previous_day")
        .all()
    )
    compliance_status = 0
    for core_powers in cores_powers:
        compliance_status += core_powers[0] >= core_powers[1]
    return compliance_status == len(cores_powers)


def obtain_quest(user):
    if UserQuest.objects.filter(active=True, user=user).count() > 0:
        raise serializers.ValidationError("There is a quest assigned to the user")
    quest = Quest.objects.order_by("?").first()
    user_quest = UserQuest.objects.create(user=user, quest=quest)
    return user_quest


def check_validation_quest(user):
    try:
        user_quest = UserQuest.objects.get(active=True, user=user)
    except UserQuest.DoesNotExist:
        raise serializers.ValidationError("There is no quest assigned to the user")
    except UserQuest.MultipleObjectsReturned:
        raise Exception("Too many quests assigned")

    quest_status = QUESTS[user_quest.quest.code_name](user)
    # If quest_status is False, closes the quest, and marks it as failed.
    if not quest_status:
        user_quest.active = False
        user_quest.success = False
        user_quest.save()
    # But if still valid, and the user ended the journey, closes the quest, and marks it as success.
    else:
        user_profile = user.user_profile
        if not user_profile.in_journey:
            user_quest.active = False
            user_quest.success = True
            user_quest.save()
            # Gives credits for completing the quest
            logger.info(f"before add credits: {user_profile.credits}")
            user = add_credits(
                user, multiplier=user_profile.days_in_journey, credits_number=25
            )
            logger.info(f"after add_credits: {user.user_profile.credits}")
    return user_quest


QUESTS = {
    "fragile_cargo": fragile_cargo,
    "navigate_safely": navigate_safely,
}
