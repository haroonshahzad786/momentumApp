"""CockpitList serializers."""

# Django
from rest_framework import serializers

# 5corelife
from cockpit_list.models import CockpitList


class CockpitListModelSerializer(serializers.ModelSerializer):
    """CockpitList model serializer."""

    class Meta:
        """Meta serializer."""

        model = CockpitList
        fields = ('id', 'name', 'description', 'enabled', 'category', 'options', 'items')
        read_only_field = ('id', 'name', 'description', 'enabled', 'options', 'category')
