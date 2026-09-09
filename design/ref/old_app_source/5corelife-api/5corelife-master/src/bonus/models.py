"""Bonus model."""

from django.db import models

from users.models import User
from utils.models import BaseCreatedUpdatedModel

INCREMENT_VALUE = 10


class Bonus(BaseCreatedUpdatedModel):

    name = models.TextField(null=False, blank=False)
    cost = models.IntegerField(null=False, blank=False, default=0)
    probability_reward = models.IntegerField(null=False, blank=False, default=0)
    description = models.TextField(blank=True)

    class Meta:
        verbose_name = 'Bonus'
        verbose_name_plural = 'Bonuses'

    def __str__(self):
        return self.name


class BonusUser(BaseCreatedUpdatedModel):

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="bonuses", null=True)
    bonus = models.ForeignKey(Bonus, on_delete=models.CASCADE, related_name='users')
    used = models.BooleanField(default=False)
    active = models.BooleanField(default=False)
    date_active = models.DateField(null=True)

    def __str__(self):
        return f'{self.bonus} | {self.user}'
