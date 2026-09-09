from django.db import models

from utils.models import BaseCreatedUpdatedModel


class Destination(BaseCreatedUpdatedModel):

    destination = models.TextField(null=False, blank=False)
    length = models.IntegerField(null=False, blank=False)
    index = models.IntegerField(null=False, blank=False, default=-1)
    momentum_required = models.IntegerField(null=False, blank=False)
    # How much cores the user gets enabled
    cores = models.IntegerField(null=False, blank=False)
    # How much core cap the user gets enabled
    core_cap = models.IntegerField(null=False, blank=False)

    class Meta:
        verbose_name = 'Destination'
        verbose_name_plural = 'Destinations'
        ordering = ['length']

    def __str__(self):
        return self.destination


class DestinationUser(BaseCreatedUpdatedModel):

    user = models.ForeignKey("users.User", on_delete=models.CASCADE, related_name="destinations", null=True)
    destination = models.ForeignKey(Destination, on_delete=models.CASCADE, related_name='destination_users')

    def __str__(self):
        return f'{self.destination} | {self.user}'
