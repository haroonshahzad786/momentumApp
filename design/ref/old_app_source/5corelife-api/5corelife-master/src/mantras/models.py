from __future__ import unicode_literals

from django.db import models

from utils.models import BaseCreatedUpdatedModel


class Mantras(BaseCreatedUpdatedModel):

    text = models.TextField('Mantra', null=False, blank=False)

    class Meta:
        verbose_name = 'Mantra'
        verbose_name_plural = 'Mantras'
