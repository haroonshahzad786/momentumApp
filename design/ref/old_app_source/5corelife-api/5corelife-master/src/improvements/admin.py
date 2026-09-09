"""Admin Improvements."""

from django.contrib import admin

from improvements.models import Improvement


@admin.register(Improvement)
class ImprovementAdmin(admin.ModelAdmin):
    list_display = ('name', 'cost', 'probability_reward', 'destination', 'improvement_type', 'default', 'order')
