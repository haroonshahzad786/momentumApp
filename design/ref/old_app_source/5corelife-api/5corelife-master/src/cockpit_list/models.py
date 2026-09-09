"""CockpitList models."""

# Django
from django.db import models
from django.contrib.postgres.fields import ArrayField, JSONField

# 5CoreLife
from utils.models import BaseCreatedUpdatedModel


class ListType(models.TextChoices):
    """ListType text choices."""

    CORE = 'CORE', 'Core'
    SORTABLE = 'SORTABLE', 'Sortable'
    CONFIGURABLE = 'CONFIGURABLE', 'Configurable'


class CockpitListBase(BaseCreatedUpdatedModel):
    """CockpitList base model."""

    name = models.CharField(max_length=100)
    description = models.CharField(max_length=300, blank=True)
    enabled = models.BooleanField(default=False)
    category = models.CharField(max_length=25, choices=ListType.choices, default=ListType.CORE)
    destination = models.ForeignKey("destinations.Destination", on_delete=models.CASCADE, null=True)
    options = ArrayField(models.CharField(max_length=50), null=True, blank=True)

    class Meta:
        """Settings model."""

        verbose_name = 'Cockpit list'
        verbose_name_plural = 'Cockpit lists'

    def __str__(self):
        return f'{self.name}'


class CockpitList(BaseCreatedUpdatedModel):
    """CockpitList model."""

    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='user_cockpitlists')
    name = models.CharField(max_length=100)
    description = models.CharField(max_length=300, blank=True)
    enabled = models.BooleanField(default=False)
    category = models.CharField(max_length=25, choices=ListType.choices, default=ListType.CORE)
    destination = models.ForeignKey("destinations.Destination", on_delete=models.CASCADE, null=True)
    options = ArrayField(models.CharField(max_length=50), null=True)
    items = JSONField(null=True)

    def __str__(self):
        return f'{self.name}'

    class Meta:
        """Settings model."""

        verbose_name = 'User Cockpit list'
        verbose_name_plural = 'User Cockpit lists'
