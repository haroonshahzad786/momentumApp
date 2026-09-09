from .models import Mantras
from rest_framework import serializers


class MantrasSerializer(serializers.ModelSerializer):
    """Mantras model serializer."""

    class Meta:
        """Meta serializer."""

        model = Mantras
        fields = ('text', )
