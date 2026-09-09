"""Inspirations view."""

# Django Rest Framework
from rest_framework.decorators import action
from rest_framework.mixins import ListModelMixin
from rest_framework.viewsets import GenericViewSet
from rest_framework import status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

# 5Corelife
from inspirations.models import Inspirations
from inspirations.serializers import InspirationsSerializer


class InspirationsViewSet(ListModelMixin, GenericViewSet):
    """Inspirations list"""

    serializer_class = InspirationsSerializer
    queryset = Inspirations.objects.all()
    permission_classes = [IsAuthenticated]

    @action(detail=False)
    def random(self, request):
        """Returns a random inspiration."""
        serializer_class = self.get_serializer_class()
        inspiration = Inspirations.objects.order_by("?").first()
        data = serializer_class(inspiration).data
        return Response(data, status=status.HTTP_200_OK)
