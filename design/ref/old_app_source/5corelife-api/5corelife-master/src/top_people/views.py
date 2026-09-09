from django.shortcuts import get_object_or_404

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import TopPeople
from .serializers import TopPeopleSerializer
from top_people import strings as top_people_strings
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

permission_classes = (IsAuthenticated,)


class TopPeopleAPI(APIView):
    """Top People API"""
    permission_classes = permission_classes

    @swagger_auto_schema(responses={200: TopPeopleSerializer})
    def get(self, request):
        """Top People API list"""
        top_people = TopPeopleSerializer(TopPeople.objects.filter(user=request.user), many=True)
        return Response(top_people.data)

    @swagger_auto_schema(responses={201: TopPeopleSerializer}, request_body=openapi.Schema(type=openapi.TYPE_OBJECT, properties={'name': openapi.Schema(type=openapi.TYPE_STRING)}))
    def post(self, request):
        """Top People API create"""
        name = request.data.get('name', None)
        if name is None:
            return Response({"error": top_people_strings.missing_parameter_name}, status=status.HTTP_400_BAD_REQUEST)
        if name == "":
            return Response({"error": top_people_strings.name_cant_be_empty}, status=status.HTTP_400_BAD_REQUEST)
        queryset = TopPeople.objects.filter(name=name, user=request.user)
        if queryset.exists():
            top_people = queryset.first()
            return Response(TopPeopleSerializer(top_people).data)
        top_people = TopPeople(name=name, user=request.user)
        top_people.save()
        return Response(TopPeopleSerializer(top_people).data, status=status.HTTP_201_CREATED)


class TopPeopleDetailAPI(APIView):
    """Top People API detail"""
    permission_classes = permission_classes

    @swagger_auto_schema(responses={200: TopPeopleSerializer})
    def get(self, request, top_people_id):
        """Top People API list"""
        try:
            return Response(TopPeopleSerializer(TopPeople.objects.get(id=top_people_id, user=request.user)).data)
        except TopPeople.DoesNotExist:
            return Response({"error": top_people_strings.top_people_not_exists}, status=status.HTTP_404_NOT_FOUND)

    @swagger_auto_schema(responses={200: TopPeopleSerializer}, request_body=openapi.Schema(type=openapi.TYPE_OBJECT, properties={'name': openapi.Schema(type=openapi.TYPE_STRING)}))
    def put(self, request, top_people_id, format=None):
        """Top People API update"""
        top_people = get_object_or_404(TopPeople.objects.all(), pk=top_people_id)
        name_data = request.data.get('name', None)
        if name_data is None:
            return Response(top_people_strings.missing_parameter_name, status=status.HTTP_400_BAD_REQUEST)
        if name_data == "":
            return Response({"error": top_people_strings.name_cant_be_empty}, status=status.HTTP_400_BAD_REQUEST)
        if TopPeople.objects.filter(name=name_data, user=request.user).exists():
            return Response({"error": top_people_strings.cannot_edit_top_people_already_exists}, status=status.HTTP_403_FORBIDDEN)
        top_people.name = name_data
        top_people.save()
        return Response(TopPeopleSerializer(top_people).data)
