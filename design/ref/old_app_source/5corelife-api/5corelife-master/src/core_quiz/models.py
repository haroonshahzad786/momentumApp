from django.db import models

from utils.models import BaseCreatedUpdatedModel
from utils.general import CoresEnum


class CoreQuiz(BaseCreatedUpdatedModel):
    """CoreQuiz model."""

    user = models.ForeignKey("users.User", on_delete=models.CASCADE, related_name="corequiz")
    core = models.CharField(max_length=50, choices=CoresEnum.choices())
    points = models.PositiveSmallIntegerField(default=0)

    def __str__(self):
        return f'{self.user} | {self.core} | {self.points}'

    class Meta:
        """Model settings."""

        verbose_name = 'Core quiz'
        verbose_name_plural = 'Core quizzes'
