"""Mission model admin."""
from django.contrib import admin

from mission.models import Mission


@admin.register(Mission)
class MissionAdmin(admin.ModelAdmin):

    list_display = ('name', 'description')

    def get_readonly_fields(self, request, obj=None):
        if obj:  # editing an existing object
            return self.readonly_fields + ('code_name',)
        return self.readonly_fields
