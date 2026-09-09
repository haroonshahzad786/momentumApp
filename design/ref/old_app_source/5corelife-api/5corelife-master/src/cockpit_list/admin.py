"""CockpitList admin."""

# Django
from django.contrib import admin

# 5corelife
from cockpit_list.models import CockpitListBase, CockpitList


@admin.register(CockpitListBase)
class CockpitListBaseAdmin(admin.ModelAdmin):

    list_display = ('name', 'category', 'enabled', 'destination', 'options')


@admin.register(CockpitList)
class CockpitListAdmin(admin.ModelAdmin):

    list_display = ('user', 'name', 'category', 'enabled', 'destination', 'options')
    search_fields = ('user__username', 'name', 'category', 'enabled', 'destination__destination', 'options')
