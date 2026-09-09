"""General utilities."""
import logging
from enum import Enum

from datetime import timedelta
from django.utils import timezone
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.template.loader import get_template, render_to_string

from users.models import EmailNotification
from users.models import PasswordRecoveryCode


logger = logging.getLogger(__name__)


class CoresEnum(Enum):
    EMOTIONAL_HEALTH = "Emotional Health"
    RELATIONSHIPS = "Relationships"
    CAREER_FINANCES = "Career & Finances"
    MINDSET = "Mindset"
    PHYSICAL_HEALTH = "Physical Health"

    @classmethod
    def choices(cls):
        return tuple((i.name, i.value) for i in cls)


def gen_code_pass_recovery(user):
    """Generate code for password recovery."""
    now = timezone.now()
    expiration_time = now + timedelta(minutes=settings.PASSWORD_RECOVERY_EXPIRATION_MIN)
    acceptance_gap = now + timedelta(seconds=60)
    recovery_pass, created = PasswordRecoveryCode.objects.get_or_create(
        user=user,
        used=False,
        expiration__gte=acceptance_gap,
        defaults={"expiration": expiration_time},
    )
    return recovery_pass.code


def send_email_verification_account(user, code, is_for_recovery=False):
    """Send generic email for account recovery or validation."""
    if is_for_recovery:
        subject = "password recovery"
        template_location = "emails/password_recovery.html"
    else:
        # subject = 'Welcome @{}! Verify your account to start using 5Corelife.'.format(user.username)
        subject = "Welcome to 5Corelife, @{}!".format(user.username)
        template_location = "emails/account_verification.html"
    context = {
        "name": user.username,
        "code": code,
    }
    if settings.DEBUG:
        logger.info("sending fake emails")
        # sent to mailhog in debug mode
        from_email = settings.DEFAULT_FROM_EMAIL
        content = render_to_string(template_location, context)
        msg = EmailMultiAlternatives(subject, content, from_email, [user.email])
        msg.attach_alternative(content, "text/html")
        msg.send()
    else:
        # SENGRID queue
        logger.info("sending real emails")
        template = get_template(template_location)
        email = EmailNotification.objects.create(
            subject=subject,
            html_body=template.template.source,
            user=user,
            context_data=context,
        )
        email.send_notification()
