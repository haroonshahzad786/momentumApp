"""Users Managers."""

from django.db import models
from django.conf import settings

# Utilities
import random
from string import digits


class PasswordRecoveryManager(models.Manager):
    """Password recovery manager.

    Used to handle code creation.
    """

    def get_or_create(self, **kwargs):
        """Handle code creation."""
        pool = digits
        code = kwargs.get('code', ''.join(random.choices(pool, k=settings.PASSWORD_RECOVERY_CODE_LENGTH)))
        defaults = kwargs.get('defaults')
        if defaults:
            defaults['code'] = code
        return super().get_or_create(**kwargs)
