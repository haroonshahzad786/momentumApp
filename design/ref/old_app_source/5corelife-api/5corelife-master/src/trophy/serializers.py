"""Trophy serializers."""

# Django REST Framework
from rest_framework import serializers

# 5CoreLife
from destinations.serializers import DestinationSerializer
from trophy.models import Trophy, TrophyUser


class TrophySerializer(serializers.ModelSerializer):
    """Trophy model serializer."""

    reach_destination = DestinationSerializer()

    class Meta:
        """Serializer settings."""

        model = Trophy
        fields = ('id', 'name', 'quantity_days', 'quantity_momentum', 'quantity_habits', 'reach_destination')


class TrophyUserSerializer(serializers.ModelSerializer):
    """Trophy User model serializer."""

    trophy = TrophySerializer()

    class Meta:
        """Serializer settings."""

        model = TrophyUser
        fields = ('trophy',)
