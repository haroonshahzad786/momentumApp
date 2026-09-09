from django.contrib import admin

from .models import Destination


class DestinationAdmin(admin.ModelAdmin):
    """Additionals settings in destination admin."""

    list_display = ('destination', 'index', 'length', 'momentum_required', 'cores', 'core_cap')


admin.site.register(Destination, DestinationAdmin)
