"""Bonus viewset."""

from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from bonus.models import Bonus, BonusUser
from bonus.serializers import (
    BonusSerializer,
    BonusUserSerializer,
    BuyBonusSerializer,
)
from users.permissions import IsObjectOwner


class BonusViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    """Viewset Bonus."""

    queryset = Bonus.objects.all()
    permission_classes = (IsAuthenticated,)

    def get_permissions(self):
        if self.action in ['user', 'buy', 'equiped']:
            permissions = (IsAuthenticated, IsObjectOwner)
            return [permission() for permission in permissions]

    def get_serializer_class(self):
        """Return serializer based on action."""
        action_mappings = {
            'user': BonusUserSerializer,
            'buy': BuyBonusSerializer,
        }
        return action_mappings.get(self.action, BonusSerializer)

    def get_queryset(self):
        if self.action in ['user', 'buy']:
            return BonusUser.objects.filter(user=self.request.user)

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
        data = BonusUserSerializer(queryset, many=True).data
        return Response(data)
