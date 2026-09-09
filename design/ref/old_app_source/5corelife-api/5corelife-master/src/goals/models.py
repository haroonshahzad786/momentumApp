from django.db import models

from utils.models import BaseCreatedUpdatedModel


class GoalUser(BaseCreatedUpdatedModel):
    """GoalUser model."""

    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='goals', null=True)

    name = models.CharField(max_length=100)
    score = models.PositiveIntegerField(default=0)
    length = models.PositiveIntegerField()
    completed = models.BooleanField(default=False)

    class Meta:
        """Model settings."""

        verbose_name = 'goal'
        verbose_name_plural = 'goals'

    def __str__(self):
        return f'{self.name} | {self.user}'

    def save(self, *args, **kwargs):
        """Set to completed when score is greater than or equal to lenght."""

        if self.pk:
            if self.score >= self.length:
                self.completed = True
        return super().save(*args, **kwargs)
