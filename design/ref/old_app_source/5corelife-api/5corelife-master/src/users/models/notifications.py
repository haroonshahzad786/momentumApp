"""Notifications model."""

# Django
from django.db import models
from django.contrib.postgres.fields import JSONField
from utils.models import BaseCreatedUpdatedModel, Notification
from django.template import (
    Template,
    Context
)


class UserDevice(BaseCreatedUpdatedModel):

    user = models.ForeignKey('users.User', related_name='devices', on_delete=models.CASCADE)
    registration_id = models.CharField(max_length=255)
    main_topic = models.CharField(max_length=255, blank=True, null=True)

    def save(self, *args, **kwargs):
        if not self.main_topic:
            self.main_topic = f'topic_user_pk_{self.main_topic}'
        return super().save(*args, **kwargs)

    def __str__(self):
        return f"User: {self.user.username} Device's."


class PushNotification(Notification):
    title = models.TextField()
    body = models.TextField()
    user_device = models.ForeignKey(
        UserDevice,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='push_notifications'
    )
    delivery_datetime = models.DateTimeField(blank=True, null=True)
    topic = models.TextField(blank=True)
    data = JSONField(default=dict, null=True, blank=True)
    color = models.CharField(max_length=50, blank=True)

    def __str__(self):
        return f"Push notification pk: {self.pk}."

    def send_notification(self):
        from users.tasks import FMCNotifications  # noqa
        service = FMCNotifications()
        service.send_notification.delay(notification_id=self.pk)


class EmailNotification(Notification):
    """Email to be sent by default account."""

    subject = models.TextField()
    to = models.EmailField(null=True, blank=True)
    user = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='email_notifications'
    )
    html_body = models.TextField(blank=True)
    text_body = models.TextField(blank=True)
    context_data = JSONField(
        default=dict,
        null=True,
        blank=True
    )

    def __str__(self):
        return f"Email notification pk: {self.pk}."

    def get_html_body(self):
        html = self.html_body
        if self.context_data:
            return Template(html).render(Context(self.context_data))
        return html

    def get_text_body(self):
        text = self.text_body
        if self.context_data and text:
            return Template(text).render(Context(self.context_data))
        return text

    def send_notification(self):
        from users.tasks import SendGridBackend
        service = SendGridBackend()
        service.send_email(email_notification_id=self.pk)
