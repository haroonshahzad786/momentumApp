"""Bonus commons."""

from bonus.models import BonusUser


def consume_bonus(user, bonus_name):
    return BonusUser.objects.filter(user=user, bonus__name=bonus_name, active=True).update(
        active=False, date_active=None, used=True
    )
