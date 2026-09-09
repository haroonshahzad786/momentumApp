from django.shortcuts import get_object_or_404

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import settings

from funeral.models import Funeral
from funeral.serializers import FuneralSerializer
from funeral import strings as strings_funeral
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

permission_classes = (IsAuthenticated,)


class FuneralAPI(APIView):
    """Funeral API """
    permission_classes = permission_classes

    @swagger_auto_schema(responses={200: FuneralSerializer})
    def get(self, request):
        """Funeral get """
        funeral = FuneralSerializer(Funeral.objects.filter(user=request.user), many=True)
        return Response(funeral.data)

    @swagger_auto_schema(responses={201: FuneralSerializer}, request_body=openapi.Schema(type=openapi.TYPE_OBJECT, properties={'funeral': openapi.Schema(type=openapi.TYPE_STRING)}))
    def post(self, request):
        """Funeral create """
        funeral = request.data.get('funeral', None)
        if funeral is None:
            return Response({"error": strings_funeral.missing_parameter_funeral}, status=settings.HTTP_400_BAD_REQUEST)
        if funeral == "":
            return Response({"error": strings_funeral.funeral_cant_be_empty}, status=settings.HTTP_400_BAD_REQUEST)
        queryset = Funeral.objects.filter(funeral=funeral, user=request.user)
        if queryset.exists():
            funeral = queryset.first()
            return Response(FuneralSerializer(funeral).data)
        funeral = Funeral(funeral=funeral, user=request.user)
        funeral.save()
        return Response(FuneralSerializer(funeral).data, status=settings.HTTP_201_CREATED)


class FuneralDetailAPI(APIView):
    """Funeral detail """
    permission_classes = permission_classes

    @swagger_auto_schema(responses={200: FuneralSerializer})
    def get(self, request, funeral_id):
        """Funeral list """
        try:
            return Response(FuneralSerializer(Funeral.objects.get(id=funeral_id, user=request.user)).data)
        except Funeral.DoesNotExist:
            return Response({"error": strings_funeral.funeral_not_exists}, status=settings.HTTP_404_NOT_FOUND)

    @swagger_auto_schema(responses={201: FuneralSerializer}, request_body=openapi.Schema(type=openapi.TYPE_OBJECT, properties={'funeral': openapi.Schema(type=openapi.TYPE_STRING)}))
    def put(self, request, funeral_id, format=None):
        """Funeral update """
        funeral = get_object_or_404(Funeral.objects.all(), pk=funeral_id)
        funeral_data = request.data.get('funeral', None)
        if funeral_data is None:
            return Response(strings_funeral.missing_parameter_funeral, status=settings.HTTP_400_BAD_REQUEST)
        if funeral_data == "":
            return Response({"error": strings_funeral.funeral_cant_be_empty}, status=settings.HTTP_400_BAD_REQUEST)
        if Funeral.objects.filter(funeral=funeral_data, user=request.user).exists():
            return Response({"error": strings_funeral.cannot_edit_funeral_already_exists}, status=settings.HTTP_403_FORBIDDEN)
        funeral.funeral = funeral_data
        funeral.save()
        return Response(FuneralSerializer(funeral).data)

    @swagger_auto_schema(responses={204: ""})
    def delete(self, request, funeral_id, format=None):
        """Funeral delete """
        funeral = get_object_or_404(Funeral.objects.all(), pk=funeral_id)
        funeral.delete()
        return Response(status=settings.HTTP_204_NO_CONTENT)
