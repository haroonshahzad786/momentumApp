from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from improvements.models import Improvement, ImprovementUser
from improvements.serializers import (
    BuyImprovementSerializer,
    EquipImprovementSerializer,
    ImprovementSerializer,
    ImprovementUserSerializer,
)
from users.permissions import IsObjectOwner


class ImprovementViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    """Viewset Improvements."""

    queryset = Improvement.objects.all()
    permission_classes = (IsAuthenticated,)

    def get_permissions(self):
        if self.action in ['user', 'buy', 'equiped']:
            permissions = (IsAuthenticated, IsObjectOwner)
        else:
            permissions = [IsAuthenticated]
        return [permission() for permission in permissions]

    def get_serializer_class(self):
        """Return serializer based on action."""
        action_mappings = {
            'user': ImprovementUserSerializer,
            'buy': BuyImprovementSerializer,
            'equip': EquipImprovementSerializer,
        }
        return action_mappings.get(self.action, ImprovementSerializer)

    def get_queryset(self):
        if self.action in ['user', 'buy', 'equip']:
            return ImprovementUser.objects.filter(user=self.request.user)
        return self.queryset.order_by('order')

    @action(detail=False)
    def user(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        serializer_class = self.get_serializer_class()
        data = serializer_class(queryset, many=True).data
        return Response(data)

    @action(detail=False, methods=['post'])
    def buy(self, request, *args, **kwargs):
        serializer_class = self.get_serializer_class()
        serializer = serializer_class(
            data=request.data,
            context={'user': request.user},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        queryset = self.filter_queryset(self.get_queryset())
        data = ImprovementUserSerializer(queryset, many=True).data
        return Response(data)

    @action(detail=False, methods=['post'])
    def equip(self, request, *args, **kwargs):
        serializer_class = self.get_serializer_class()
        serializer = serializer_class(
            data=request.data,
            context={'user': request.user},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        queryset = self.filter_queryset(self.get_queryset())
        data = ImprovementUserSerializer(queryset, many=True).data
        return Response(data)
