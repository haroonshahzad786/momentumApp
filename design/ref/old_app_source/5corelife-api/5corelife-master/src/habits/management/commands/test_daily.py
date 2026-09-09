
# Django
from django.core.management.base import BaseCommand
from habits.tasks import update_dailycheck


class Command(BaseCommand):

    def handle(self, *args, **options):
        print(update_dailycheck())
