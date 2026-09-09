from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Destination
from .serializers import DestinationSerializer
from drf_yasg.utils import swagger_auto_schema


class DestinationAPI(APIView):
    """Destination API"""
    permission_classes = (IsAuthenticated,)

    @swagger_auto_schema(responses={200: DestinationSerializer})
    def get(self, request):
        destinations = DestinationSerializer(Destination.objects.all(), many=True)
        return Response(destinations.data)
