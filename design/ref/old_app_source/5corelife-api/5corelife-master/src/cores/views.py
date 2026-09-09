"""Core User views."""

# Django Rest Framework
from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

# 5CoreLife
from cores.models import CoreUser
from cores.serializers import CoreUserSerializer, EnableCoreUserSerializer
from utils.general import CoresEnum


class CoreViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    """Core view set."""

    queryset = CoreUser.objects.all()
    permission_classes = (IsAuthenticated,)

    def list(self, request, *args, **kwargs):
        """Returns list of cores."""
        cores = [core.name for core in CoresEnum]
        return Response(cores)

    @action(detail=False, methods=['get', 'post'], url_path='user')
    def user_cores(self, request, *args, **kwargs):
        """Returns user cores."""
        cores_user = CoreUser.objects.filter(user=request.user)
        if request.method == 'GET':
            data = CoreUserSerializer(cores_user, many=True).data
        else:
            serializer = EnableCoreUserSerializer(
                data=request.data,
                context={'request': request},
            )
            serializer.is_valid(raise_exception=True)
            core_user = cores_user.filter(core_string=request.data.get('core')).first()
            core_user.enabled = True
            core_user.save()
            data = CoreUserSerializer(core_user).data

        return Response(data)
