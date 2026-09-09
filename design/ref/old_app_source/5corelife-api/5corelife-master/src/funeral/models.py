from django.db import models

from utils.models import BaseCreatedUpdatedModel
from users.models import User


class Funeral(BaseCreatedUpdatedModel):

    funeral = models.TextField(null=False, blank=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="funerals", null=True)

    class Meta:
        verbose_name = 'Funeral'
        verbose_name_plural = 'Funerals'

    def __str__(self):
        return ": ".join((str(self.user), self.funeral))
