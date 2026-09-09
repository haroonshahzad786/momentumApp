from rest_framework import serializers

from .models import Fear


class FearSerializer(serializers.ModelSerializer):

    class Meta:
        model = Fear
        fields = ('id', 'fear', 'user')
