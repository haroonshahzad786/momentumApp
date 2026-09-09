"""Habits Tasks."""

# Datetime
from datetime import timedelta

import pytz

# Celery
from celery.task import periodic_task
from celery.schedules import crontab
from django.conf import settings
from django.utils import timezone

# 5CoreLife
from bonus.commons import consume_bonus
from bonus.strings import SKIP_CHECK_IN
from cores.models import CoreUser
from habits.models import DailyCheck
from users.commons import create_push_notifications
from users.models import UserProfile


def drops_point(user):
    """If the user misses a daily check-in, core power and total momentum, drops by 4 points."""
    if consume_bonus(user, SKIP_CHECK_IN):
        return

    coreuser = CoreUser.objects.filter(user=user, enabled=True)
    for core in coreuser:
        core.power_previous_day = core.power
        core.power -= 4
        core.power = max(core.power, 0)
        core.save()


@periodic_task(run_every=crontab(minute='*/2'))
def update_dailycheck():
    current_time = timezone.localtime()
    profiles_without_pause = UserProfile.objects.filter(pause=False)
    dailyopen = DailyCheck.objects.filter(open=True, user__user_profile__in=profiles_without_pause)
    result = []
    if dailyopen:
        for daily in dailyopen:
            user = daily.user
            hour_for_user = user.time_for_user(current_time)
            night_check = timezone.datetime.combine(hour_for_user.date(), user.user_profile.night_check_time)
            if hour_for_user.now() > (night_check + timedelta(hours=4)):
                drops_point(daily.user)
                result.append(user.pk)
        DailyCheck.objects.filter(user__pk__in=result).update(open=False)
    return result


@periodic_task(name='daily_checks', run_every=crontab(day_of_week='*', hour=4))
def daily_checks():
    """Pre schedule daily checks for the next day."""
    server_timezone = pytz.timezone(settings.TIME_ZONE)
    tomorrow = timezone.localtime() + timedelta(days=1)
    profiles_without_pause = UserProfile.objects.filter(pause=False, notifications=True)
    # Get tomorow's date of server
    for profile in profiles_without_pause:
        if profile.user.has_device:
            # schedule for users timezone
            if profile.user.tz_zone != server_timezone:
                morning_time = profile.time_to_server('morning', tomorrow)
                night_time = profile.time_to_server('night', tomorrow)
            else:
                morning_time = timezone.datetime.combine(tomorrow, profile.morning_check_time)
                night_time = timezone.datetime.combine(tomorrow, profile.night_check_time)

            create_push_notifications(profile, morning_time, night_time)

    return True
