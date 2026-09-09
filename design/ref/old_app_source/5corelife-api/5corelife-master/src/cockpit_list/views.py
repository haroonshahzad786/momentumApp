"""CockpitList views."""

# Django Rest Framework
from rest_framework.mixins import (
    ListModelMixin,
    RetrieveModelMixin,
    UpdateModelMixin,
)
from rest_framework.permissions import IsAuthenticated
from rest_framework.viewsets import GenericViewSet

# 5corelife
from cockpit_list.models import CockpitList
from cockpit_list.serializers import CockpitListModelSerializer
from users.permissions import IsObjectOwner


class CockpitListViewSet(ListModelMixin, RetrieveModelMixin, UpdateModelMixin, GenericViewSet):
    """CockpitList view set."""

    permissions = (IsAuthenticated, IsObjectOwner)
    serializer_class = CockpitListModelSerializer

    def get_queryset(self):
        """Return the user's cockpit list."""
        return CockpitList.objects.filter(user=self.request.user).order_by('-enabled')
