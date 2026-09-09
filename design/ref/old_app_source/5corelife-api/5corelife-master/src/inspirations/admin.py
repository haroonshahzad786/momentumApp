"""Inspirations admin."""
from django.contrib import admin

from .models import Inspirations


@admin.register(Inspirations)
class InspirationsAdmin(admin.ModelAdmin):

    list_display = ('text', )
    list_filter = ['id']
    search_fields = ['text']
