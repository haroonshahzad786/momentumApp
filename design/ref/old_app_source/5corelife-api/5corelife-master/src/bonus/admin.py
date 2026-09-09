from django.contrib import admin

from bonus.models import Bonus


@admin.register(Bonus)
class BonusAdmin(admin.ModelAdmin):
    list_display = ('name', 'cost', 'probability_reward')
