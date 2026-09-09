"""Django models utilities."""

# Django
from django.contrib.postgres.fields import JSONField
from django.db import models


class BaseCreatedUpdatedModel(models.Model):
    """Base model.
    BaseCreatedUpdatedModel acts as an abstract base class from which every
    other model in the project will inherit. This class provides
    every table with the following attributes:
        + created (DateTime): Store the datetime the object was created.
        + modified (DateTime): Store the last datetime the object was modified.
    """

    created = models.DateTimeField(
        'created at', auto_now_add=True, help_text='Date time on which the object was created.'
    )
    modified = models.DateTimeField(
        'modified at', auto_now=True, help_text='Date time on which the object was last modified.'
    )

    class Meta:
        abstract = True
        get_latest_by = 'created'
        ordering = ['-created', '-modified']


class Notification(BaseCreatedUpdatedModel, models.Model):
    """Generic notification model por emails and push models."""

    QUEUED = 'QUEUED'
    PENDING = 'PENDING'
    IN_PROGRESS = 'IN_PROGRESS'
    SENT = 'SENT'
    FAILED = 'FAILED'
    NOT_SENT = 'NOT_SENT'

    STATUSES = (
        (QUEUED, QUEUED),
        (PENDING, PENDING),
        (IN_PROGRESS, IN_PROGRESS),
        (SENT, SENT),
        (FAILED, FAILED),
        (NOT_SENT, NOT_SENT),
    )

    sent = models.DateTimeField(null=True, blank=True)
    attempts = models.IntegerField(default=0)
    status = models.CharField(max_length=50, default=PENDING, choices=STATUSES)
    request_body = JSONField(default=dict, null=True, blank=True)
    request_response = JSONField(default=dict, null=True, blank=True)

    class Meta:
        abstract = True
