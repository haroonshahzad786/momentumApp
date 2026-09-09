"""CockpitList serializers."""

# Django
from rest_framework import serializers

# 5corelife
from goals.models import GoalUser


class GoalUserModelSerializer(serializers.ModelSerializer):
    """GoalUser model serializer."""

    user = serializers.HiddenField(default=serializers.CurrentUserDefault())

    class Meta:
        """Meta serializer."""

        model = GoalUser
        fields = ('id', 'name', 'score', 'length', 'completed', 'user')
        read_only_field = ('id', 'score', 'completed', 'user')
