from django.shortcuts import get_object_or_404

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import Fear
from .serializers import FearSerializer
from fears import strings as fears_strings
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

permission_classes = (IsAuthenticated,)


class FearAPI(APIView):
    """Fear  API"""
    permission_classes = permission_classes

    @swagger_auto_schema(responses={200: FearSerializer})
    def get(self, request):
        """Fear  list"""
        fears = FearSerializer(Fear.objects.filter(user=request.user), many=True)
        return Response(fears.data)

    @swagger_auto_schema(responses={201: FearSerializer}, request_body=openapi.Schema(type=openapi.TYPE_OBJECT, properties={'fear': openapi.Schema(type=openapi.TYPE_STRING)}))
    def post(self, request):
        """Fear create."""
        fear = request.data.get('fear', None)
        if fear is None:
            return Response({"error": fears_strings.missing_parameter_fear}, status=status.HTTP_400_BAD_REQUEST)
        if fear == "":
            return Response({"error": fears_strings.fear_cant_be_empty}, status=status.HTTP_400_BAD_REQUEST)
        queryset = Fear.objects.filter(fear=fear, user=request.user)
        if queryset.exists():
            fear = queryset.first()
            return Response(FearSerializer(fear).data)
        fear = Fear(fear=fear, user=request.user)
        fear.save()
        return Response(FearSerializer(fear).data, status=status.HTTP_201_CREATED)


class FearDetailAPI(APIView):
    """Fear  detail"""
    permission_classes = permission_classes

    @swagger_auto_schema(responses={200: FearSerializer})
    def get(self, request, fear_id):
        """Fear  list """
        try:
            return Response(FearSerializer(Fear.objects.get(id=fear_id, user=request.user)).data)
        except Fear.DoesNotExist:
            return Response({"error": fears_strings.fear_not_exists}, status=status.HTTP_404_NOT_FOUND)

    @swagger_auto_schema(responses={201: FearSerializer}, request_body=openapi.Schema(type=openapi.TYPE_OBJECT, properties={'fear': openapi.Schema(type=openapi.TYPE_STRING)}))
    def put(self, request, fear_id, format=None):
        """Fear update."""
        fear = get_object_or_404(Fear.objects.all(), pk=fear_id)
        fear_data = request.data.get('fear', None)
        if fear_data is None:
            return Response(fears_strings.missing_parameter_fear, status=status.HTTP_400_BAD_REQUEST)
        if fear_data == "":
            return Response({"error": fears_strings.fear_cant_be_empty}, status=status.HTTP_400_BAD_REQUEST)
        if Fear.objects.filter(fear=fear_data, user=request.user).exists():
            return Response({"error": fears_strings.cannot_edit_fear_already_exists}, status=status.HTTP_403_FORBIDDEN)
        fear.fear = fear_data
        fear.save()
        return Response(FearSerializer(fear).data)

    @swagger_auto_schema(responses={204: ""})
    def delete(self, request, fear_id, format=None):
        """Fear  delete """
        fear = get_object_or_404(Fear.objects.all(), pk=fear_id)
        fear.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
