"""CoreUser model."""

from django.db import models

from improvements.models import ImprovementUser
from utils.models import BaseCreatedUpdatedModel

POWER_MULTIPLIER = 3


class CoreUser(BaseCreatedUpdatedModel):

    user = models.ForeignKey("users.User", on_delete=models.CASCADE, related_name="cores", null=True)
    core_string = models.TextField(null=False, blank=False, default="")
    enabled = models.BooleanField(default=False)
    # Internal, use core_power to read the full status
    power = models.IntegerField(null=False, blank=False, default=0)
    # Core power from previous day, automatically updated
    power_previous_day = models.IntegerField(null=False, blank=False, default=0)

    def __str__(self):
        return " ".join((self.user.username, self.core_string, str(self.enabled)))

    def add_core_power(self, power, user_profile):
        self.power_previous_day = self.power
        improvement_user = ImprovementUser.objects.filter(
            user=self.user,
            improvement__improvement_type='THRUSTER',
            improvement__core_power_multiplier__gt=0,
            equipped=True,
        ).first()
        if improvement_user:
            new_power = power * improvement_user.improvement.core_power_multiplier
        else:
            new_power = power * POWER_MULTIPLIER

        if new_power > user_profile.user_core_cap:
            self.power = user_profile.user_core_cap
        else:
            self.power += new_power

    @property
    def core_power(self):
        return self.power + self.user.user_profile.core_power_increase
