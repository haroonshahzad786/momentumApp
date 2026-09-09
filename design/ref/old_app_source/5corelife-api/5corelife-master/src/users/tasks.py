"""Users tasks."""

import logging
from datetime import timedelta
from typing import List
from typing import Optional

from celery import Task
from celery.task import periodic_task
# Django
from django.conf import settings
from django.db.models import Q
from django.utils import timezone
from pyfcm import FCMNotification
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

# Services
from config import celery_app
# 5corelife
from habits.models import DailyCheck
from users.models import EmailNotification
from users.models import PushNotification
from users.models import User

logger = logging.getLogger(__name__)


class FMCNotifications:
    """Push notifications service."""

    def __init__(self):
        self.task = Task()

    @celery_app.task(
        bind=True,
        name='send_notification_push',
        autoretry_for=(Exception,),
        retry_backoff=True,
        retry_kwargs={'max_retries': 5},
    )
    def send_notification(self, notification_id):
        notification = PushNotification.objects.get(id=notification_id)
        if notification.delivery_datetime:
            # Check hour for scheduled notification
            if notification.delivery_datetime >= timezone.now():
                return 'Skip notification will be deliveried at scheduled hour'
        registration_ids = notification.user_device.registration_id
        title = notification.title
        body = notification.body
        data = notification.data
        color = notification.color
        push_service = FCMNotification(api_key=settings.FCM_API_KEY)

        # Send notification to specific ids
        single_device_configuration = {
            'registration_id': registration_ids,
            'message_title': title,
            'message_body': body,
            'data_message': data,
            'color': color,
        }
        notification.request_body = single_device_configuration
        single_device_response = {}
        try:
            single_device_response = push_service.notify_single_device(**single_device_configuration)
            notification.request_response = single_device_response
            if single_device_response.get('success'):
                status = PushNotification.SENT
            else:
                status = PushNotification.NOT_SENT
        except Exception as e:
            status = PushNotification.FAILED
            logger.error(f"push notification error: {e}")
            self.task.retry(exc=e)

        notification.status = status
        notification.attempts += 1
        if status == PushNotification.SENT:
            notification.sent = timezone.now()
        notification.save(update_fields=['status', 'attempts', 'sent', 'request_body', 'request_response'])
        logger.info(f"send_notification: {single_device_response}")


class SendGridBackend:
    """Send `EmailNotification` email trough sendgrid api."""

    @celery_app.task(
        bind=True,
        name='sendgrid_backend_send_email',
        autoretry_for=(Exception,),
        retry_backoff=True,
        retry_kwargs={'max_retries': 5},
    )
    def send_email(self, email_notification_id):
        """Send email with sendgrind based on email notification."""
        status_sent = EmailNotification.SENT
        notification = EmailNotification.objects.get(id=email_notification_id)
        attempts = notification.attempts

        if notification.status == status_sent:
            return
        data = {
            'from_email': settings.DEFAULT_FROM_EMAIL,
            'to_emails': notification.user.email if notification.user else notification.email,
            'subject': notification.subject,
            'html_content': notification.get_html_body() or None,
        }
        message = Mail(
            from_email=data.get('from_email'),
            to_emails=data.get('to_emails'),
            subject=data.get('subject'),
            html_content=data.get('html_content'),
        )
        notification.request_body = data
        attempt_date = timezone.now()
        try:
            sg = SendGridAPIClient(settings.SENGRID_API_KEY)
            response = sg.send(message)
            notification.request_response = {'status_code', response.status_code}
            if response.status_code in [202, 200, 201, 202]:
                status = status_sent
                notification.sent = timezone.now()
            else:
                status = EmailNotification.FAILED
        except Exception as e:
            status = EmailNotification.FAILED
            logger.error(f'Failed to send notification ID:{email_notification_id} due to {e}')

        notification.status = status
        notification.attempt_date = attempt_date
        notification.attempts = attempts + 1
        notification.save(update_fields=['status', 'attempts', 'sent', 'request_body', 'request_response'])


@periodic_task(name="delete_notification_status_pending_with_night_daily_check", run_every=timedelta(minutes=15))
def delete_notification_status_pending_with_night_daily_check():
    """
    Check notifications with status pending and title night daily check.
    If not return daily check by users, delete the notifications.
    If return daily check by users without morning check, delete the notifications
    """
    for notification in __get_all_push_notification():
        if 'night daily' in notification.title.lower():
            daily_checks: List[Optional[DailyCheck]] = __get_daily_checks_users(notification)
            __delete_notification_with_daily_check_by_user_none(daily_checks, notification)
            __delete_notification_with_daily_check_by_user_without_morning_check(daily_checks, notification)


def __get_all_push_notification() -> List[PushNotification]:
    """Get a list all push_notification"""
    notifications = PushNotification.objects.filter(
        status=PushNotification.PENDING, delivery_datetime__lte=timezone.now(),
        user_device__registration_id__isnull=False
    )
    return notifications


def __get_daily_checks_users(notification: PushNotification) -> List[DailyCheck]:
    """Get a list DailyCheck by user with notification"""
    daily_checks_users = DailyCheck.objects.filter(
        user=notification.user_device.user, created__startswith=timezone.now().date()
    )
    return daily_checks_users


def __delete_notification_with_daily_check_by_user_none(daily_checks_users: List[DailyCheck],
                                                        notification: PushNotification) -> None:
    """Delete notification when DailyCheck by User will be False"""
    if not daily_checks_users:
        notification.delete()


def __delete_notification_with_daily_check_by_user_without_morning_check(daily_checks: List[Optional[DailyCheck]],
                                                                         notification: PushNotification) -> None:
    """Delete notification when DailyCheck by User without morning check"""
    for daily_checks_user in daily_checks:
        if not daily_checks_user.morningcheck:
            notification.delete()


@periodic_task(name="push_notification_deliveries", run_every=timedelta(minutes=15, seconds=10))
def push_notification_deliveries():
    """Check for pending notifications scheduled."""
    for notification in __get_all_push_notification():
        notification.send_notification()


@periodic_task(name='remove_notification_deliveries', run_every=timedelta(minutes=5))
def remove_notification_deliveries():
    """Remove notification deliveries if user stopped notifications."""
    user_notifications_off = User.objects.filter(user_profile__notifications=False).values_list("pk", flat=True)
    PushNotification.objects.filter(
        Q(status=PushNotification.PENDING) | Q(status=PushNotification.QUEUED) | Q(status=PushNotification.IN_PROGRESS),
        user_device__user__pk__in=[user_notifications_off],
    ).delete()
