from django.db import models

from users.models import User


class Quest(models.Model):
    name = models.CharField(max_length=100)
    description = models.CharField(max_length=100)
    code_name = models.CharField(max_length=55, unique=True)

    def __str__(self):
        return f'{self.name}'


class UserQuest(models.Model):
    quest = models.ForeignKey(Quest, null=True, on_delete=models.CASCADE, related_name="user_quests")
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="user_quests")
    active = models.BooleanField(default=True)
    success = models.BooleanField(default=False)

    def __str__(self):
        return f'{self.quest.name} | {self.user.username}'
