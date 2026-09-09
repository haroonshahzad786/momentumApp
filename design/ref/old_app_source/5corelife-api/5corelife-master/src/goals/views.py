"""Goal views."""

# Django Rest Framework
from rest_framework.mixins import (
    CreateModelMixin,
    DestroyModelMixin,
    ListModelMixin,
    RetrieveModelMixin,
    UpdateModelMixin,
)
from rest_framework.permissions import IsAuthenticated
from rest_framework.viewsets import GenericViewSet

# 5corelife
from goals.models import GoalUser
from goals.serializers import GoalUserModelSerializer
from users.permissions import IsObjectOwner


class GoalUserViewSet(
    ListModelMixin, CreateModelMixin, RetrieveModelMixin, UpdateModelMixin, DestroyModelMixin, GenericViewSet
):
    """GoalUser view set."""

    permissions = (IsAuthenticated, IsObjectOwner)
    serializer_class = GoalUserModelSerializer

    def get_queryset(self):
        """Return the user's goal list."""
        return GoalUser.objects.filter(user=self.request.user)
