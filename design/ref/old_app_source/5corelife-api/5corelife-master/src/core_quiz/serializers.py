"""Core Quiz serializers."""

# Django
from rest_framework import serializers

# 5corelife
from core_quiz.models import CoreQuiz


class CoreQuizModelSerializer(serializers.ModelSerializer):
    """Core Quiz model serializer."""

    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    points = serializers.IntegerField(min_value=0, max_value=6)

    class Meta:
        """Meta serializer."""

        model = CoreQuiz
        fields = ('core', 'points', 'user')
