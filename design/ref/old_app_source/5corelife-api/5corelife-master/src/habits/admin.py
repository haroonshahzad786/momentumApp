"""Habits admin."""
from django.contrib import admin

from habits.models import DailyCheck, Habits, HabitsBase


@admin.register(DailyCheck)
class DailyCheckAdmin(admin.ModelAdmin):

    list_display = ('user', 'core', 'morningcheck', 'nightcheck', 'created')


@admin.register(HabitsBase)
class HabitsBaseAdmin(admin.ModelAdmin):

    list_display = ('name', 'positive', 'core')
    list_filter = ('core',)
    search_fields = ('name', 'core')


@admin.register(Habits)
class HabitsAdmin(admin.ModelAdmin):

    list_display = ('user', 'name', 'positive', 'core')
    list_filter = ('core',)
    search_fields = ('name', 'core')
