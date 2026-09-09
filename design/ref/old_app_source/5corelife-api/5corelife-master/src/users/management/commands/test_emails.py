
# Django
from django.core.management.base import BaseCommand
from users.models import EmailNotification, User
from django.template.loader import get_template


class Command(BaseCommand):

    def handle(self, *args, **options):
        user = User.objects.get(username='ducode@outlook.com')
        template = get_template('emails/signup.html')
        email = EmailNotification.objects.create(
            subject='Test',
            html_body=template.template.source,
            user=user,
            context_data={
                'user': 'Ducode',
                'url': 'https://ducode.com',
            }
        )
        email.send_notification()
