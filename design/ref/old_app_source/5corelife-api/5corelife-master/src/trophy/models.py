"""Trophy models."""

# Django
from django.db import models

# 5Corelife
from destinations.models import Destination
from users.models import User
from utils.models import BaseCreatedUpdatedModel


class Trophy(BaseCreatedUpdatedModel):

    name = models.TextField(null=False, blank=False)
    quantity_days = models.IntegerField(null=False, blank=False, default=0)
    quantity_momentum = models.IntegerField(null=False, blank=False, default=0)
    quantity_habits = models.IntegerField(null=False, blank=False, default=0)
    reach_destination = models.ForeignKey(
        Destination, on_delete=models.CASCADE, related_name="trophy_related", blank=True, null=True, default=None
    )

    class Meta:
        verbose_name = 'Trophy'
        verbose_name_plural = 'Trophies'

    def __str__(self):
        return self.name


class TrophyUser(BaseCreatedUpdatedModel):

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="trophies", null=True)
    trophy = models.ForeignKey(Trophy, on_delete=models.CASCADE, related_name='users')
