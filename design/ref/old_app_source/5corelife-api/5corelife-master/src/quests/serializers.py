"""Quests serializers."""

# Django REST Framework
from rest_framework import serializers

# 5CoreLife
from quests.models import UserQuest


class UserQuestSerializer(serializers.ModelSerializer):
    """UserQuest model serializer."""

    class Meta:
        """Serializer settings."""

        model = UserQuest
        fields = ("quest", "active", "success")


class UserQuestSuccessSerializer(serializers.ModelSerializer):
    """UserQuest success serializer."""

    quest_name = serializers.CharField()

    class Meta:
        """Serializer settings."""

        model = UserQuest
        fields = ("quest_name", "success")
        read_only_fields = ("active",)

    def validate_quest_name(self, attr):
        """Validate mission name."""
        user = self.context.get('user')
        try:
            user_quest = UserQuest.objects.get(quest_name=attr, user=user)
            if user_quest.success:
                raise serializers.ValidationError('UserQuest is completed.')
        except UserQuest.DoesNotExist:
            raise serializers.ValidationError('UserQuest does not exist.')
        return user_quest

    def save(self, **kwargs):
        """Update UserQuest."""
        user_quest = self.validated_data.get('quest_name')
        user_quest.success = True
        user_quest.save()
        return user_quest
