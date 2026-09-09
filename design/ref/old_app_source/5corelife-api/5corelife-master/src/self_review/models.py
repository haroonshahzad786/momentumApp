from datetime import date

from django.db import models

from utils.models import BaseCreatedUpdatedModel
from users.models import User


class Answer(BaseCreatedUpdatedModel):
    answer = models.TextField(null=False, blank=False)
    question_number = models.IntegerField()
    self_review = models.ForeignKey("SelfReview", on_delete=models.CASCADE, related_name="answers", null=True)

    class Meta:
        verbose_name = 'Answer'
        verbose_name_plural = 'Answers'

    def __str__(self):
        return self.answer


class SelfReview(BaseCreatedUpdatedModel):
    date = models.DateField(default=date.today)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="self_review", null=True)

    class Meta:
        verbose_name = 'Self review'
        verbose_name_plural = 'Self reviews'

    def __str__(self):
        return f'{self.user} - {self.date}'
