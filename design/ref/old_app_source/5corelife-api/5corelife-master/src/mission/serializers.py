"""Missions serializers."""

# Django REST Framework
from rest_framework import serializers

# Model
from mission.models import UserMission


class UserMissionSerializer(serializers.ModelSerializer):
    """UserMission Model serializer."""

    class Meta:
        """Serializer settings."""

        model = UserMission
        fields = ("mission", "active", "success")


class UserMissionSuccessSerializer(serializers.ModelSerializer):
    """UserMission success serializer."""

    mission_name = serializers.CharField()
    success = serializers.BooleanField()

    class Meta:
        """Serializer settings."""

        model = UserMission
        fields = ("mission_name", "active", "success")
        read_only_fields = ("mission_name", "active")

    def validate_mission_name(self, attr):
        """Validate mission name."""
        user = self.context.get('user')
        try:
            user_mission = UserMission.objects.get(mission__name=attr, user=user, active=True)
        except UserMission.DoesNotExist:
            raise serializers.ValidationError(f'Mission {attr} does not exist for this user.')
        return user_mission

    def save(self, **kwargs):
        """Update UserMission."""
        success = self.validated_data.get('success')
        user_mission = self.validated_data.get('mission_name')
        user_mission.success = success
        user_mission.active = False
        user_mission.save()
        return user_mission
