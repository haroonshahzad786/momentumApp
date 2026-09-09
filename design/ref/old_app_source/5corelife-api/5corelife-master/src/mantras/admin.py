
from django.contrib import admin

from .models import Mantras


@admin.register(Mantras)
class MantrasAdmin(admin.ModelAdmin):

    list_display = ('text', )
