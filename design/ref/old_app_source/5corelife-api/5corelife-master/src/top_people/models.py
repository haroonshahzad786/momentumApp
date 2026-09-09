from django.db import models

from utils.models import BaseCreatedUpdatedModel
from users.models import User


class TopPeople(BaseCreatedUpdatedModel):

    name = models.TextField(null=False, blank=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="top_people", null=True)

    class Meta:
        verbose_name = 'Top person'
        verbose_name_plural = 'Top people'
