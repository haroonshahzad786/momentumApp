from rest_framework import serializers

from .models import TopPeople


class TopPeopleSerializer(serializers.ModelSerializer):

    class Meta:
        model = TopPeople
        fields = ('id', 'name', 'user')
