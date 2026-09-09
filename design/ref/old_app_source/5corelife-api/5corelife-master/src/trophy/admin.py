"""Trophies admin."""
from django.contrib import admin

from trophy.models import Trophy


@admin.register(Trophy)
class TrophiesAdmin(admin.ModelAdmin):

    list_display = ('name', 'quantity_days', 'quantity_momentum', 'quantity_habits', 'reach_destination')
    search_fields = ('name',)
