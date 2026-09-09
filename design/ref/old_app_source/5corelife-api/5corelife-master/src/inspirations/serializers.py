from .models import Inspirations
from rest_framework import serializers


class InspirationsSerializer(serializers.ModelSerializer):
    """Inspirations model serializer."""

    class Meta:
        """Meta serializer."""

        model = Inspirations
        fields = ('text', )
