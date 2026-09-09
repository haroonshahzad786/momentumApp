"""User commons."""
import logging

# Goal model
from goals.models import GoalUser
from users.models import PushNotification

logger = logging.getLogger(__name__)


def add_credits(user, multiplier=1, credits_number=25):
    """Increase credits to the user's profile."""
    total_credits = credits_number * multiplier
    user.user_profile.credits += total_credits
    user.user_profile.score += total_credits
    user.user_profile.save()

    # Goals
    goals_user = GoalUser.objects.filter(user=user, completed=False)
    logger.info(f"goals_user: {goals_user}")
    for goal in goals_user:
        goal.score = +total_credits
        goal.save()
    return user


def create_push_notifications(
    user_profile, morning_time=None, night_time=None, update=False
):
    """Create or update push notifications."""

    # Morning push
    if morning_time:
        push_morning = PushNotification.objects.filter(
            user_device=user_profile.get_main_device,
            title="Morning Daily Check",
            delivery_datetime__year=morning_time.year,
            delivery_datetime__month=morning_time.month,
            delivery_datetime__day=morning_time.day,
        ).first()

        if not push_morning:
            PushNotification.objects.create(
                user_device=user_profile.get_main_device,
                title="Morning Daily Check",
                body="Warm up ship! Remember to review your purpose",
                delivery_datetime=morning_time,
            )
        if push_morning and update:
            push_morning.delivery_datetime = night_time
            push_morning.save()

    if night_time:
        push_night = PushNotification.objects.filter(
            user_device=user_profile.get_main_device,
            title="Night Daily Check",
            delivery_datetime__year=night_time.year,
            delivery_datetime__month=night_time.month,
            delivery_datetime__day=night_time.day,
        ).first()

        if not push_night:
            PushNotification.objects.get_or_create(
                user_device=user_profile.get_main_device,
                title="Night Daily Check",
                body="Ship Diagnostics! Remember to review your day",
                delivery_datetime=night_time,
            )
        if push_night and update:
            push_night.delivery_datetime = night_time
            push_night.save()
