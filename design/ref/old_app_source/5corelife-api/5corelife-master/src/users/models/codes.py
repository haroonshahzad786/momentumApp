"""Redemption codes model."""

# Django
from django.db import models
from django.conf import settings
from django.contrib.postgres.fields import JSONField
from utils.models import BaseCreatedUpdatedModel
import pandas as pd


class RedemptionCode(BaseCreatedUpdatedModel):
    code = models.CharField(max_length=8, unique=True)
    redeemed_by = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='redeemed_codes', null=True, blank=True)
    claimed_date = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Code: {self.code}."


class CodeFile(BaseCreatedUpdatedModel):

    file = models.FileField(upload_to='codes/')
    proccessed = models.BooleanField(default=False)
    result = JSONField(null=True, blank=True)

    def __str__(self):
        return f"File uploaded {self.created}."

    def save(self, *args, **kwargs):
        """Save the code file."""
        super().save(*args, **kwargs)
        if not self.proccessed:
            result = {}
            if settings.DEBUG:
                url = self.file.file
            else:
                url = self.file.url
            data = pd.read_csv(url)
            for index, data in data.iterrows():
                code = data.get('code')
                # validate lenght
                if len(code) == 8:
                    # Save code
                    RedemptionCode.objects.get_or_create(code=code)
                    result[index] = {'code': code, 'status': 'success'}
                else:
                    result[index] = {'code': code, 'status': 'skiped', 'reason': 'invalid length'}
            self.result = result
            self.proccessed = True
            self.save()
