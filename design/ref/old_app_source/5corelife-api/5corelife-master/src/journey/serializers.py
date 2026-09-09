"""Journey serializer."""

# Django REST Framework
from rest_framework import serializers


class JourneySerializer(serializers.Serializer):
    """Journey serializer."""

    status = serializers.CharField()
    days_in_journey = serializers.CharField()
    actual_destination = serializers.CharField()
    next_destination = serializers.CharField()
