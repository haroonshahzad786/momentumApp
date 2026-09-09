"""Quests views."""

# Django REST Framework
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import GenericViewSet

# 5CoreLife
from quests.models import UserQuest
from quests.serializers import UserQuestSerializer, UserQuestSuccessSerializer
from users.permissions import IsObjectOwner


class UserQuestsViewSet(GenericViewSet):
    """UserQuest ViewSet"""

    permissions = (IsAuthenticated, IsObjectOwner)
    queryset = UserQuest.objects.all()

    def get_serializer_class(self):
        """Return serializer based on action."""
        action_mappings = {
            'success': UserQuestSuccessSerializer,
        }
        return action_mappings.get(self.action, UserQuestSerializer)

    @action(detail=False)
    def user(self, request):
        """Return user's quests."""
        user = request.user
        serializer_class = self.get_serializer_class()
        missions_user = UserQuest.objects.filter(user=user)
        data = serializer_class(missions_user, many=True).data
        return Response(data, status=status.HTTP_200_OK)

    @action(detail=False, methods=['POST'])
    def success(self, request):
        """Complete a quests."""
        serializer_class = self.get_serializer_class()
        serializer = serializer_class(
            data=request.data,
            context={'user': request.user},
        )
        serializer.is_valid(raise_exception=True)
        quest = serializer.save()
        data = UserQuestSerializer(quest).data

        return Response(data, status=status.HTTP_200_OK)
