from rest_framework import serializers

from .models import Funeral


class FuneralSerializer(serializers.ModelSerializer):

    class Meta:
        model = Funeral
        fields = ('id', 'funeral', 'user')
