from django.db import models

from utils.models import BaseCreatedUpdatedModel
from users.models import User


class Fear(BaseCreatedUpdatedModel):

    fear = models.TextField(null=False, blank=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="fears", null=True)

    class Meta:
        verbose_name = 'Fear'
        verbose_name_plural = 'Fears'
