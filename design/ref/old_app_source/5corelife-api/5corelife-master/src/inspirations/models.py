"""Inspirations models."""
from __future__ import unicode_literals

from django.db import models

from utils.models import BaseCreatedUpdatedModel


class Inspirations(BaseCreatedUpdatedModel):

    text = models.TextField('Inspiration', null=False, blank=False)

    class Meta:
        verbose_name = 'Inspiration'
        verbose_name_plural = 'Inspirations'
