from django.db import models

from destinations.models import Destination
from utils.models import BaseCreatedUpdatedModel


class ImprovementType(models.TextChoices):
    ARMOR = 'ARMOR', 'Armor'
    WINGS = 'WINGS', 'Wings'
    THRUSTER = 'THRUSTER', 'Thruster'


class Improvement(BaseCreatedUpdatedModel):

    name = models.CharField(max_length=255)
    cost = models.DecimalField(
        blank=True,
        decimal_places=2,
        max_digits=12,
        default=0.0,
        help_text='Amount of credits the item/improvement costs.',
    )
    probability_reward = models.IntegerField(
        null=False,
        blank=False,
        default=0,
        help_text='Chance of item dropping as a reward. 0% for items that cannot drop.',
    )
    destination = models.ForeignKey(
        Destination, on_delete=models.CASCADE, null=True, blank=True, related_name='improvements'
    )
    improvement_type = models.CharField(max_length=55, choices=ImprovementType.choices, blank=True)
    default = models.BooleanField(default=False)
    order = models.PositiveSmallIntegerField(blank=True, default=0)
    bonus_core_cap = models.PositiveSmallIntegerField(blank=True, default=0)
    core_power_multiplier = models.PositiveSmallIntegerField(blank=True, default=0)

    class Meta:
        verbose_name = 'Improvement'
        verbose_name_plural = 'Improvements'

    def __str__(self):
        return self.name


class ImprovementUser(BaseCreatedUpdatedModel):

    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name="improvements", null=True)
    improvement = models.ForeignKey(Improvement, on_delete=models.CASCADE, related_name='users')
    equipped = models.BooleanField(default=False)
