"""Habits serializers."""

# Django
from django.core.validators import MaxValueValidator, MinValueValidator
from django.utils import timezone
from rest_framework import serializers

# 5CoreLife
from cores.models import CoreUser
from cores.serializers import CoreUserSerializer
from habits.models import DailyCheck, DailyHabits, Habits
from trophy.serializers import TrophyUserSerializer
from utils.general import CoresEnum


class HabitsModelSerializer(serializers.ModelSerializer):
    """Habits model serializer."""

    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    positive = serializers.BooleanField()
    favorite = serializers.BooleanField()

    class Meta:
        """Meta serializer."""

        model = Habits
        fields = (
            'id',
            'name',
            'positive',
            'description',
            'core',
            'formed',
            'favorite',
            'user',
            'selected',
            'selected_date',
        )

    def create(self, validated_data):
        user = validated_data.get('user')

        habit = Habits.objects.filter(
            user=user,
            name=validated_data.get('name'),
            positive=validated_data.get('positive'),
            core=validated_data.get('core'),
        ).first()

        if habit:
            raise serializers.ValidationError('Habit already exists.')

        habit = Habits.objects.create(
            user=user,
            name=validated_data.get('name'),
            positive=validated_data.get('positive'),
            description=validated_data.get('description'),
            core=validated_data.get('core'),
            favorite=validated_data.get('favorite'),
        )
        return habit

    def update(self, instance, validated_data):
        """If habit is selected, save a date when this happens."""
        Habits.objects.filter(pk=instance.pk).update(**validated_data)
        instance.refresh_from_db()
        if instance.selected:
            instance.selected_date = timezone.now().date()
        else:
            instance.selected_date = None
        instance.save()
        return instance


class DailyCheckModelSerializer(serializers.ModelSerializer):
    """DailyCheck model serializer."""

    class Meta:
        """Serializer settings."""

        model = DailyCheck
        fields = ('score', 'morningcheck', 'nightcheck', 'open', 'core', 'created')


class DailyCheckSerializer(serializers.Serializer):
    """Dailycheck serializer."""

    dailychecks = DailyCheckModelSerializer(many=True)
    user_profile = serializers.SerializerMethodField(read_only=True)
    cores = serializers.SerializerMethodField(read_only=True)
    journey = serializers.SerializerMethodField(read_only=True)
    quest = serializers.SerializerMethodField(read_only=True)
    mission = serializers.SerializerMethodField(read_only=True)
    reward = serializers.SerializerMethodField(read_only=True)
    trophies = serializers.SerializerMethodField(read_only=True)

    def get_user_profile(self, instance):
        """Returns user credits."""
        user_profile = self.context.get('user_profile')
        return {'credits': user_profile.credits}

    def get_cores(self, instance):
        """Returns user cores."""
        user_profile = self.context.get('user_profile')
        queryset = CoreUser.objects.filter(user=user_profile.user)
        return CoreUserSerializer(queryset, many=True).data

    def get_journey(self, instance):
        """Returns journey status"""
        user_profile = self.context.get('user_profile')
        status = self.context.get('journey_status') or 'In progress'
        return {
            'status': status,
            'days_in_journey': user_profile.days_in_journey,
            'actual_destination': user_profile.actual_destination,
            'next_destination': user_profile.next_destination,
        }

    def get_quest(self, instance):
        """Returns assigned quest."""
        user_quest = self.context.get('quest', None)
        if hasattr(user_quest, 'quest'):
            return {
                'name': user_quest.quest.name,
                'description': user_quest.quest.description,
                'active': user_quest.active,
                'success': user_quest.success,
            }
        return {}

    def get_mission(self, instance):
        """Returns assigned mission."""
        user_mission = self.context.get('mission', None)
        if user_mission:
            return {
                'name': user_mission.mission.name,
                'description': user_mission.mission.description,
                'active': user_mission.active,
                'success': user_mission.success,
            }
        return {}

    def get_reward(self, instance):
        """Returns reward."""
        return self.context.get('reward') or {}

    def get_trophies(self, instance):
        """Returns user trophies."""
        trophies = self.context.get('trophies', None)
        return TrophyUserSerializer(trophies, many=True).data if trophies else {}


class MorningCheckSerializer(serializers.Serializer):
    """Morning check serializer."""

    core = serializers.CharField()
    habits = serializers.ListField()

    def validate_core(self, attr):
        """Validate core."""
        if attr not in [core.name for core in CoresEnum]:
            raise serializers.ValidationError('Core invalid.')

        self.context['core'] = attr
        return attr

    def validate_habits(self, attr):
        """Validate habit ids."""
        core = self.context.get('core')
        habits = []

        for idx in attr:
            try:
                habits.append(Habits.objects.get(pk=idx, core=core))
            except Habits.DoesNotExist:
                raise serializers.ValidationError('Habits does not exist.')

        return habits

    def validate(self, attrs):
        """Validate dailycheck."""
        core = attrs.get('core')
        today = timezone.now().date()
        user = self.context.get('user')

        if DailyCheck.objects.filter(user=user, core=core, created__startswith=today).exists():
            raise serializers.ValidationError({'core': 'Morning check exists.'})

        if not CoreUser.objects.filter(user=user, core_string=core, enabled=True).exists():
            raise serializers.ValidationError({'core': f'The {core} core is disabled.'})

        return attrs

    def create(self, validated_data):
        """Create dailycheck."""
        core = validated_data.get('core')
        habits = validated_data.get('habits')
        user = self.context.get('user')

        dailycheck = DailyCheck.objects.create(user=user, core=core, open=True, morningcheck=True)
        for habit in habits:
            DailyHabits.objects.create(habit=habit, dailycheck=dailycheck)

        return dailycheck


class NightCheckSerializer(serializers.Serializer):
    """Night check serializer."""

    core = serializers.CharField()
    score = serializers.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])

    def validate_core(self, attr):
        """Validate core."""
        if attr not in [core.name for core in CoresEnum]:
            raise serializers.ValidationError('Core invalid.')

        self.context['core'] = attr
        return attr

    def validate(self, attrs):
        """Validate dailycheck."""
        core = attrs.get('core')
        user = self.context.get('user')
        if not CoreUser.objects.filter(user=user, core_string=core, enabled=True).exists():
            raise serializers.ValidationError({'core': f'The {core} core is disabled.'})
        return attrs

    def create(self, validated_data):
        """Update dailycheck."""
        today = timezone.now().date()
        core = validated_data.get('core')
        score = validated_data.get('score')
        user = self.context.get('user')

        # Update dailycheck
        try:
            dailycheck = DailyCheck.objects.get(core=core, user=user, created__startswith=today)
        except DailyCheck.DoesNotExist:
            raise serializers.ValidationError("Daily Check doesn't exist for this user.")

        if not dailycheck.open:
            raise serializers.ValidationError('This dailycheck is closed.')

        dailycheck.score = score
        dailycheck.nightcheck = True
        dailycheck.open = False
        dailycheck.save()

        # CoreUser
        try:
            coreuser = CoreUser.objects.get(user=user, core_string=dailycheck.core)
        except CoreUser.DoesNotExist:
            raise serializers.ValidationError('CoreUser not exists')

        coreuser.add_core_power(score, user.user_profile)
        coreuser.save()

        return dailycheck


class DailyCheckDeleteSerializer(serializers.Serializer):
    """Dailycheck delete serializer."""

    habit = serializers.IntegerField()
    dailycheck = serializers.IntegerField()

    def validate_habit(self, attr):
        """Validate habit."""
        try:
            Habits.objects.get(pk=attr)
        except Habits.DoesNotExist:
            raise serializers.ValidationError('Habit does not exist.')
        return attr

    def validate_dailycheck(self, attr):
        """Validate dailycheck."""
        try:
            DailyCheck.objects.get(pk=attr)
        except DailyCheck.DoesNotExist:
            raise serializers.ValidationError('DailyCheck Does not exist.')
        return attr
