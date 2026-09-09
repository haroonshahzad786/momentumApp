"""Self review admin."""

from self_review.models import Answer, SelfReview
from django.contrib import admin


@admin.register(Answer)
class AnswerAdmin(admin.ModelAdmin):
    """Admin for self review."""

    list_display = ('id', 'answer', 'question_number', 'self_review')
    search_fields = ('self_review__user__username',)


@admin.register(SelfReview)
class SelfReviewAdmin(admin.ModelAdmin):
    """Admin for self review."""

    list_display = ('id', 'user', 'created')
    search_fields = ('user__username',)
