"""CoreView views."""

# Django Rest Framework
from rest_framework.mixins import (
    CreateModelMixin,
    ListModelMixin,
    RetrieveModelMixin,
)
from rest_framework.permissions import IsAuthenticated
from rest_framework.viewsets import GenericViewSet
from rest_framework import status
from rest_framework.response import Response

# 5corelife
from core_quiz.models import CoreQuiz
from core_quiz.serializers import CoreQuizModelSerializer
from users.permissions import IsObjectOwner


class CoreQuizViewSet(ListModelMixin, CreateModelMixin, RetrieveModelMixin, GenericViewSet):
    """CoreQuiz view set."""

    permissions = (IsAuthenticated, IsObjectOwner)
    serializer_class = CoreQuizModelSerializer

    def get_queryset(self):
        """Return the user's cockpit list."""
        return CoreQuiz.objects.filter(user=self.request.user)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, many=True)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
