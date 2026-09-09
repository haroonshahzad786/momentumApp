"""Mission models."""

from django.db import models


class Mission(models.Model):
    name = models.CharField(max_length=100)
    description = models.CharField(max_length=100)
    code_name = models.CharField(max_length=55, unique=True)

    def __str__(self):
        return f'{self.name}'


class UserMission(models.Model):
    """User mission model."""

    mission = models.ForeignKey(Mission, null=True, on_delete=models.CASCADE, related_name="user_missions")
    user = models.ForeignKey("users.User", on_delete=models.CASCADE, related_name="user_missions")
    active = models.BooleanField(default=True)
    success = models.BooleanField(default=False)

    def __str__(self):
        return f'{self.mission.name} | {self.user}'
