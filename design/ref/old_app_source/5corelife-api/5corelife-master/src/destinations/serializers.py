from rest_framework import serializers

from .models import Destination


class DestinationSerializer(serializers.ModelSerializer):

    class Meta:
        model = Destination
        fields = ('destination', 'length', 'momentum_required',  'cores',
                  'core_cap')
