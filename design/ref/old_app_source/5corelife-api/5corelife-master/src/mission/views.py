"""Missions views."""

# Django REST Framework
from rest_framework import mixins, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import GenericViewSet

# 5CoreLife
from mission.models import UserMission
from mission.serializers import (
    UserMissionSerializer,
    UserMissionSuccessSerializer,
)
from users.commons import add_credits
from utils.constants import CREDITS_MISSION


class UserMissionViewSet(mixins.UpdateModelMixin, GenericViewSet):
    """UserMission ViewSet"""

    permissions = (IsAuthenticated,)
    queryset = UserMission.objects.all()

    def get_serializer_class(self):
        """Return serializer based on action."""
        action_mappings = {
            'success': UserMissionSuccessSerializer,
        }
        return action_mappings.get(self.action, UserMissionSerializer)

    @action(detail=False)
    def user(self, request):
        """Return user's missions."""
        user = request.user
        serializer_class = self.get_serializer_class()
        missions_user = UserMission.objects.filter(user=user)
        data = serializer_class(missions_user, many=True).data
        return Response(data, status=status.HTTP_200_OK)

    @action(detail=False, methods=['POST'])
    def success(self, request):
        """Return user's missions."""
        serializer_class = self.get_serializer_class()
        serializer = serializer_class(
            data=request.data,
            context={'user': request.user},
        )
        serializer.is_valid(raise_exception=True)
        mission_user = serializer.save()
        if mission_user.success:
            add_credits(request.user, credits_number=CREDITS_MISSION)
        data = UserMissionSerializer(mission_user).data

        return Response(data, status=status.HTTP_200_OK)
