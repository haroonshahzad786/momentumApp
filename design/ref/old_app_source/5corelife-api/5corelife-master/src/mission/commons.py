"""Missions commons."""

import datetime
from statistics import mean

# 5corelife
from cores.models import CoreUser
from habits.models import DailyCheck
from mission.exceptions import MissionNotAssigned
from mission.models import Mission, UserMission
from users.commons import add_credits
from utils.constants import BALANCED_CORES_PERCENTAGE, CREDITS_MISSION


def balanced_cores(user):
    """
    Validates the completion of this mission. Calculates the range, and must not be greather than 40% from the lower
    value. Returns a boolean with the status result.

    Parameters:
    user (User): An user

    Returns:
    boolean: Success status of the mission
    """
    try:
        user_mission = UserMission.objects.get(mission__code_name="balanced_cores", active=True, user=user)
    except Exception:
        raise MissionNotAssigned
    cores_user = CoreUser.objects.filter(user=user).exclude(power=0)
    cores = sorted(cores_user, key=lambda core: core.power)
    # In percentage, the difference between the maximum and the minimum can't be greather than 0.4
    result = ((cores[len(cores) - 1].power / cores[0].power) - 1) > BALANCED_CORES_PERCENTAGE
    user_mission.success = result
    user_mission.active = False
    user_mission.save()
    if user_mission.success:
        add_credits(user, credits_number=CREDITS_MISSION)
    return user_mission


def previous_day(user):
    """
    Validates the completion of this mission. Checks that the power from the cores, won't be lower than the previous day
    Returns a boolean with the status result.

    Parameters:
    user (User): An user

    Returns:
    boolean: Success status of the mission
    """
    try:
        user_mission = UserMission.objects.get(mission__code_name="previous_day", active=True, user=user)
    except Exception:
        raise MissionNotAssigned
    result = 0
    cores_user = CoreUser.objects.filter(user=user)
    for core in cores_user:
        if core.power >= core.power_previous_day:
            result += 1
    # All cores must meet the condition
    user_mission.success = result == len(cores_user)
    user_mission.active = False
    user_mission.save()
    if user_mission.success:
        add_credits(user, credits_number=CREDITS_MISSION)
    return user_mission


def core_lower(user):
    """
    Validates the completion of this mission. Calculates an average with the points, and must be greater than 3.
    Returns a boolean with the status result.

    Parameters:
    user (User): An user

    Returns:
    boolean: Success status of the mission
    """
    try:
        user_mission = UserMission.objects.get(mission__code_name="core_lower", active=True, user=user)
    except Exception:
        raise MissionNotAssigned
    scores = [d.score for d in DailyCheck.objects.filter(user=user, created__startswith=datetime.date.today())]
    result = mean(scores) > 3
    user_mission.success = result
    user_mission.active = False
    user_mission.save()
    if user_mission.success:
        add_credits(user, credits_number=CREDITS_MISSION)
    return user_mission


def obtain_mission(user):
    """Obtain a random mission.

    First deactivate previously assigned missions.
    """
    UserMission.objects.filter(active=True, user=user).update(active=False)
    mission = Mission.objects.order_by('?').first()
    user_mission = UserMission.objects.create(user=user, mission=mission)
    return user_mission


MISSIONS = {
    "comfort_zone": None,  # The user verifies the mission
    "balanced_cores": balanced_cores,
    "previous_day": previous_day,
    "core_lower": core_lower,
}
