"""Cores serializers."""

# Django REST Framework
from rest_framework import serializers

# 5CoreLife
from cores.models import CoreUser
from cores.strings import max_core_count_reached
from destinations.models import Destination
from destinations.strings import destination_not_exists
from utils.general import CoresEnum


class CoreUserSerializer(serializers.ModelSerializer):
    """Core user serializer."""

    core_power = serializers.ReadOnlyField()

    class Meta:
        """Serializer settings."""

        model = CoreUser
        fields = ('user', 'core_string', "enabled", "core_power")


class EnableCoreUserSerializer(serializers.Serializer):
    """Enable a user core."""

    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    core = serializers.CharField()

    def validate_core(self, attr):
        """Validate core."""
        if attr not in [core.name for core in CoresEnum]:
            raise serializers.ValidationError('Core invalid.')

        return attr

    def validate(self, attrs):
        """Validate user destination."""
        user = attrs.get('user')
        queryset = Destination.objects.filter(index=user.user_profile.destination_index)

        if not queryset.exists():
            raise serializers.ValidationError({'user': destination_not_exists})
        destination = queryset.first()
        if CoreUser.objects.filter(enabled=True, user=user).count() >= destination.cores:
            raise serializers.ValidationError({'user': max_core_count_reached})

        return attrs
