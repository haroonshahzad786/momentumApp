"""Habits models."""
from __future__ import unicode_literals

from django.db import models
from django.utils import timezone

from utils.general import CoresEnum
from utils.models import BaseCreatedUpdatedModel


class HabitsBase(BaseCreatedUpdatedModel):

    name = models.CharField(max_length=100, null=False, blank=False)
    positive = models.BooleanField(default=False)
    description = models.TextField(null=False, blank=False)
    core = models.CharField(max_length=50, choices=CoresEnum.choices())

    class Meta:
        verbose_name = 'Habit'
        verbose_name_plural = 'Habits'


class Habits(BaseCreatedUpdatedModel):

    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='userhabits')
    name = models.CharField(max_length=100, null=False, blank=False)
    positive = models.BooleanField(default=False)
    description = models.TextField(null=False, blank=False)
    core = models.CharField(max_length=50, choices=CoresEnum.choices())
    formed = models.BooleanField(default=False)
    favorite = models.BooleanField(default=False)
    selected = models.BooleanField(default=False)
    selected_date = models.DateField(null=True)


class DailyCheck(models.Model):

    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='usercheck')
    score = models.PositiveIntegerField(default=0)
    morningcheck = models.BooleanField(default=False)
    nightcheck = models.BooleanField(default=False)
    open = models.BooleanField(default=True)
    core = models.CharField(max_length=50, choices=CoresEnum.choices())

    def __str__(self):
        return f'{self.user} | {self.core}'

    created = models.DateTimeField('created at', help_text='Date time on which the object was created.')

    modified = models.DateTimeField(
        'modified at', auto_now=True, help_text='Date time on which the object was last modified.'
    )

    class Meta:
        get_latest_by = 'created'
        ordering = ['-created', '-modified']

    def save(self, *args, **kwargs):
        """Overwrite created data for testing purposes."""
        if not self.pk:
            self.created = timezone.now()
        return super().save(*args, **kwargs)


class DailyHabits(BaseCreatedUpdatedModel):

    dailycheck = models.ForeignKey(DailyCheck, on_delete=models.CASCADE, related_name='checkdaily')
    habit = models.ForeignKey('habits.Habits', on_delete=models.CASCADE, related_name='habitdaily')
