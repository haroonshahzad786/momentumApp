from rest_framework.mixins import ListModelMixin
from rest_framework.viewsets import GenericViewSet

from rest_framework.permissions import (
    IsAuthenticated
)

from .serializers import MantrasSerializer
from .models import Mantras


class MantrasViewSet(ListModelMixin, GenericViewSet):
    """Mantra list"""
    serializer_class = MantrasSerializer
    queryset = Mantras.objects.all()
    permission_classes = [IsAuthenticated, ]
