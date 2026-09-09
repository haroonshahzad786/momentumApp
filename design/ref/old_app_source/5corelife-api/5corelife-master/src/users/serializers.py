"""Users Serializers."""

import pytz

# Django
from django.conf import settings
from django.contrib.auth import authenticate, password_validation
from django.db.models import Avg
from django.utils import timezone

# Django REST Framework
from rest_framework import serializers
from rest_framework.authtoken.models import Token
from rest_framework.validators import UniqueValidator
from rest_framework_csv.renderers import CSVRenderer

# Utils
from timezone_field.rest_framework import TimeZoneSerializerField

# 5Corelife
from cockpit_list.models import CockpitList
from cores.models import CoreUser
from destinations.models import Destination
from improvements.models import ImprovementUser
from users.commons import create_push_notifications
from users.models import (
    PasswordRecoveryCode,
    RedemptionCode,
    User,
    UserDevice,
    UserProfile,
)
from utils.general import (
    CoresEnum,
    gen_code_pass_recovery,
    send_email_verification_account,
)


class UserProfileModelSerializer(serializers.ModelSerializer):
    """User profile serializer."""

    onboarding = serializers.BooleanField(required=False)
    quiz = serializers.BooleanField(required=False)
    morning_check_time = serializers.TimeField(format='%H:%M', input_formats=['%H:%M'], required=False)
    night_check_time = serializers.TimeField(format='%H:%M', input_formats=['%H:%M'], required=False)

    cores_active = serializers.SerializerMethodField(read_only=True)
    cores_available = serializers.SerializerMethodField(read_only=True)
    code_redemption = serializers.SerializerMethodField(read_only=True)

    class Meta:
        """Serializer settings."""

        model = UserProfile
        fields = (
            'credits',
            'momentum',
            'night_checks_in_row',
            'last_night_check',
            'core_power_increase',
            'days_in_journey',
            'in_journey',
            'morning_check_time',
            'night_check_time',
            'pause',
            'notifications',
            'user_core_cap',
            'actual_destination',
            'actual_destination_length',
            'onboarding',
            'quiz',
            'cores_active',
            'cores_available',
            'score',
            'code_redemption',
        )

        read_only_fields = (
            'credits',
            'momentum',
            'night_checks_in_row',
            'last_night_check',
            'core_power_increase',
            'days_in_journey',
            'in_journey',
            'user_core_cap',
            'actual_destination',
            'actual_destination_length',
            'cores_active',
            'cores_available',
            'code_redemption',
        )

    def get_cores_active(self, instance):
        """Returns user cores active."""
        return CoreUser.objects.filter(user=instance.user, enabled=True).count()

    def get_cores_available(self, instance):
        """Returns user cores available."""
        return Destination.objects.filter(index=instance.destination_index).values_list('cores', flat=True)[0]

    def get_code_redemption(self, instance):
        """Return if user has redeemed a code."""
        return bool(len(instance.user.redeemed_codes.all())) if hasattr(instance.user, 'redeemed_codes') else False


class UserModelSerializer(serializers.ModelSerializer):
    """User model serializer."""

    user_profile = UserProfileModelSerializer(required=False)

    class Meta:
        """Meta serializer."""

        model = User
        fields = (
            'username',
            'first_name',
            'last_name',
            'email',
            'is_verified',
            'user_profile',
        )

    def update(self, instance, validated_data):
        """Update user."""
        user_profile = validated_data.pop('user_profile', None)

        User.objects.filter(pk=instance.pk).update(**validated_data)
        instance.refresh_from_db()

        if user_profile:
            UserProfile.objects.filter(user=instance).update(**user_profile)
            instance.user_profile.refresh_from_db()

            # Notifications
            if not instance.user_profile.pause and instance.user_profile.notifications and instance.has_device:
                server_timezone = pytz.timezone(settings.TIME_ZONE)
                today = timezone.localtime()
                if instance.tz_zone != server_timezone:
                    morning_time = instance.user_profile.time_to_server('morning', today)
                    night_time = instance.user_profile.time_to_server('night', today)
                else:
                    morning_time = timezone.datetime.combine(today, instance.user_profile.morning_check_time)
                    night_time = timezone.datetime.combine(today, instance.user_profile.night_check_time)

                if user_profile.get('morning_check_time') and today.now().time() < morning_time.time():
                    create_push_notifications(instance.user_profile, morning_time=morning_time, update=True)

                if user_profile.get('night_check_time') and today.now().time() < night_time.time():
                    create_push_notifications(instance.user_profile, night_time=night_time, update=True)

        return instance


class UserLoginSerializer(serializers.Serializer):
    """Users login Serializer.

    Handle login request data.
    """

    username = serializers.CharField()
    password = serializers.CharField(min_length=8)
    registration_id = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        """Check credentials."""
        user = authenticate(username=attrs['username'], password=attrs['password'])
        if not user:
            raise serializers.ValidationError('Invalid credential')
        if not hasattr(user, "user_profile"):
            raise serializers.ValidationError('User profile does not exist')
        self.context['user'] = user
        return attrs

    def create(self, validated_data):
        """Generate or retrieve new token."""
        user = self.context.get('user')
        token, _ = Token.objects.get_or_create(user=user)
        registration_id = validated_data.get('registration_id', None)
        if registration_id and not user.devices.filter(registration_id=registration_id).exists():
            UserDevice.objects.create(user=user, registration_id=registration_id)

        return self.context['user'], token.key


class ForgotPasswordSerializer(serializers.Serializer):
    """Forgot password serializer."""

    email = serializers.EmailField()

    def create(self, validated_data):
        """Send email to user if exists."""
        email = validated_data.get('email')
        user = User.objects.filter(email=email)
        if not user:
            raise serializers.ValidationError('Invalid email')

        if user.exists():
            # Send Email
            user = user.last()
            code = gen_code_pass_recovery(user)
            send_email_verification_account(user, code, is_for_recovery=True)
        return user


class UserSignUpSerializer(serializers.Serializer):
    """Users signup serializer.

    Handle sign up data validation and user
    """

    username = serializers.CharField(min_length=1, max_length=150, required=True)
    email = serializers.EmailField(validators=[UniqueValidator(queryset=User.objects.all())])
    # Password
    password = serializers.CharField(max_length=14, min_length=4)
    password_confirmation = serializers.CharField(max_length=14, min_length=4)

    # Name
    first_name = serializers.CharField(min_length=1, required=False)
    last_name = serializers.CharField(min_length=1, required=False)
    registration_id = serializers.CharField(min_length=1, required=False)
    tz_zone = TimeZoneSerializerField(default=settings.TIME_ZONE)

    def validate(self, attrs):
        """Verify password match."""
        passwd = attrs.get('password')
        passwd_conf = attrs.get('password_confirmation')
        if passwd != passwd_conf:
            raise serializers.ValidationError('Passwords do not match.')
        password_validation.validate_password(passwd)

        username = attrs.get('username')
        if User.objects.filter(username=username):
            raise serializers.ValidationError('Username already exists.')
        return attrs

    def create(self, validated_data):
        """Handle user creation."""
        registration_id = None
        validated_data.pop('password_confirmation')
        if 'registration_id' in validated_data:
            registration_id = validated_data.pop('registration_id')
        user = User.objects.create_user(**validated_data)

        if registration_id:
            user.devices.create(registration_id=registration_id)

        # Send email
        code = gen_code_pass_recovery(user)
        send_email_verification_account(user, code)

        return user


class PasswordResetSerializer(serializers.Serializer):
    """Password reset serializer."""

    email = serializers.EmailField()
    password = serializers.CharField(min_length=8)
    password_confirmation = serializers.CharField(min_length=8)
    code = serializers.CharField()

    def validate_password(self, attr):
        """Verify password match."""
        passwd = attr
        passwd_conf = self.initial_data.get('password_confirmation')
        if passwd != passwd_conf:
            raise serializers.ValidationError("Passwords does not match.")
        password_validation.validate_password(passwd)
        return attr

    def validate(self, attrs):
        user = User.objects.filter(email=attrs.get('email'))
        if not user.exists():
            raise serializers.ValidationError('Email invalid.')

        user = user.last()
        self.context['user'] = user
        # Check code existence.
        code = PasswordRecoveryCode.objects.filter(
            user=user, used=False, code=attrs.get('code'), expiration__gte=timezone.now()
        )
        if not code.exists():
            raise serializers.ValidationError('Invalid code.')

        self.context['code'] = code
        return attrs

    def create(self, validated_data):
        """Update password."""
        user = self.context.get('user')
        user.set_password(validated_data.get('password'))
        user.save(update_fields=['password'])
        # Used flag code
        self.context.get('code').update(used=True)
        # Delete existing code
        Token.objects.filter(user=user).delete()
        return True


class UserMantraSerializer(serializers.ModelSerializer):
    """User model serializer."""

    class Meta:
        """Meta serializer."""

        model = User
        fields = ('id', 'mantra')


class AccountVerificationSerializer(serializers.Serializer):
    """Account verification serializer"""

    code = serializers.CharField()

    def validate_code(self, data):
        """Verify code is valid"""
        user = self.context.get('user')
        code = PasswordRecoveryCode.objects.filter(user=user, used=False, code=data, expiration__gte=timezone.now())
        if not code.exists():
            raise serializers.ValidationError('Invalid code.')

        self.context['code'] = code

        return data

    def save(self):
        """Update user's verified status"""
        user = self.context.get('user')
        # Used flag code
        self.context.get('code').update(used=True)
        user.is_verified = True
        user.save()


class ExportCSVRenderer(CSVRenderer):
    header = [
        'Username',
        'Momentum',
        'Mindset score',
        'Mindset habits',
        'Relationships score',
        'Relationships habits (current)',
        'Relationships habits (formed)',
        'Career & Finances',
        'Career & Finances habits (current)',
        'Career & Finances habits (formed)',
        'Emotional Health',
        'Emotional Health habits (current)',
        'Emotional Health habits (formed)',
        'Physical Health',
        'Physical Health habits (current)',
        'Physical Health habits (formed)',
        'Captains log (each day with their 3 answers)',
        'Lists (unlocked)',
    ]

    def get_data(self, user):
        """Get data for CSV"""
        # minset data
        mindset_habits = ' | '.join([e.name for e in user.userhabits.filter(core=CoresEnum.MINDSET.name)])
        mindset_score = user.usercheck.filter(core=CoresEnum.MINDSET.name).aggregate(Avg('score')).get('score__avg')

        # relationships data
        relationships_habits = ' | '.join([e.name for e in user.userhabits.filter(core=CoresEnum.RELATIONSHIPS.name)])
        formed_relationships_habits = ' | '.join(
            [e.name for e in user.userhabits.filter(formed=True, core=CoresEnum.RELATIONSHIPS.name)]
        )
        relationships_score = (
            user.usercheck.filter(core=CoresEnum.RELATIONSHIPS.name).aggregate(Avg('score')).get('score__avg')
        )

        # Career data
        career_habits = ' | '.join([e.name for e in user.userhabits.filter(core=CoresEnum.CAREER_FINANCES.name)])
        formed_career_habits = ' | '.join(
            [e.name for e in user.userhabits.filter(formed=True, core=CoresEnum.CAREER_FINANCES.name)]
        )
        career_score = (
            user.usercheck.filter(core=CoresEnum.CAREER_FINANCES.name).aggregate(Avg('score')).get('score__avg')
        )

        # Emotional data
        emotional_habits = ' | '.join([e.name for e in user.userhabits.filter(core=CoresEnum.EMOTIONAL_HEALTH.name)])
        formed_emotional_habits = ' | '.join(
            [e.name for e in user.userhabits.filter(formed=True, core=CoresEnum.EMOTIONAL_HEALTH.name)]
        )
        emotional_score = (
            user.usercheck.filter(core=CoresEnum.EMOTIONAL_HEALTH.name).aggregate(Avg('score')).get('score__avg')
        )

        # Physical data
        # TODO: Calcule formed
        physical_habits = ' | '.join([e.name for e in user.userhabits.filter(core=CoresEnum.PHYSICAL_HEALTH.name)])
        formed_physical_habits = ' | '.join(
            [e.name for e in user.userhabits.filter(formed=True, core=CoresEnum.PHYSICAL_HEALTH.name)]
        )
        physical_score = (
            user.usercheck.filter(core=CoresEnum.PHYSICAL_HEALTH.name).aggregate(Avg('score')).get('score__avg')
        )

        # Captain logs
        self_reviews = user.self_review.all()
        captain_logs = []
        for review in self_reviews:
            responses = review.answers.all()
            for response in responses:
                captain_logs.append(
                    '{} | question #{} | Response:{}'.format(
                        review.date.strftime('%Y-%m-%d'),
                        response.question_number,
                        response.answer,
                    )
                )
        # user_cockpitlists
        user_cockpitlists = user.user_cockpitlists.all()
        cockpitlists = []
        for item in user_cockpitlists:
            cockpitlists.append(
                'Name:{} | Description:{} | Category:{} | Destination:{}'.format(
                    item.name,
                    item.description,
                    item.category,
                    item.destination,
                )
            )
        return [
            {
                'Username': user.username,
                'Momentum': user.user_profile.momentum,
                'Mindset score': mindset_score or 0.0,
                'Mindset habits': mindset_habits,
                'Relationships score': relationships_score or 0.0,
                'Relationships habits (current)': relationships_habits,
                'Relationships habits (formed)': formed_relationships_habits,
                'Career & Finances': career_score or 0.0,
                'Career & Finances habits (current)': career_habits,
                'Career & Finances habits (formed)': formed_career_habits,
                'Emotional Health': emotional_score or 0.0,
                'Emotional Health habits (current)': emotional_habits,
                'Emotional Health habits (formed)': formed_emotional_habits,
                'Physical Health': physical_score or 0.0,
                'Physical Health habits (current)': physical_habits,
                'Physical Health habits (formed)': formed_physical_habits,
                'Captains log (each day with their 3 answers)': '\n'.join(captain_logs),
                'Lists (unlocked)': '\n'.join(cockpitlists),
            }
        ]


class CodeRedemptionSerializer(serializers.Serializer):

    code = serializers.CharField(max_length=8, min_length=8)

    def validate_code(self, value):
        """Check if code exists and is not used."""
        user = self.context.get('request').user
        if user.redeemed_codes.exists():
            raise serializers.ValidationError('User already redeemed a code.')
        elif RedemptionCode.objects.filter(code=value).exists():
            code = RedemptionCode.objects.get(code=value)
            if bool(code.redeemed_by):
                raise serializers.ValidationError('Code already used.')
        else:
            raise serializers.ValidationError('Code not found.')
        return value

    def save(self):
        """Asociate redemption to user."""
        user = self.context.get('request').user
        code = RedemptionCode.objects.get(code=self.validated_data.get('code'))
        code.redeemed_by = user
        code.claimed_date = timezone.now()
        code.save()
        code.refresh_from_db()
        CoreUser.objects.filter(user=user).update(enabled=True)
        CockpitList.objects.filter(user=user).update(enabled=True)
        return code


class LeaderboardSerializer(serializers.Serializer):

    username = serializers.SerializerMethodField(read_only=True)
    score = serializers.SerializerMethodField(read_only=True)
    armor = serializers.SerializerMethodField(read_only=True)
    destination = serializers.SerializerMethodField(read_only=True)

    def get_username(self, instance):
        return instance.username

    def get_score(self, instance):
        return instance.user_profile.score if hasattr(instance, 'user_profile') else 0

    def get_armor(self, instance):
        improvement_user = ImprovementUser.objects.filter(
            user=instance, improvement__improvement_type='ARMOR', equipped=True
        ).first()
        armor = None
        if improvement_user:
            armor = improvement_user.improvement.name
        return armor

    def get_destination(self, instance):
        return instance.user_profile.actual_destination if hasattr(instance, 'user_profile') else None
