"""Quest model admin."""
from django.contrib import admin
from quests.models import Quest


@admin.register(Quest)
class QuestAdmin(admin.ModelAdmin):

    list_display = ('name', 'description')

    def get_readonly_fields(self, request, obj=None):
        if obj:  # editing an existing object
            return self.readonly_fields + ('code_name',)
        return self.readonly_fields
