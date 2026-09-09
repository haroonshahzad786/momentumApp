"""Cores URLs."""

from django.urls import include, path
from rest_framework.routers import DefaultRouter

# Viewsets
from cores.views import CoreViewSet

app_name = "cores"
router = DefaultRouter()
router.register(r'cores', CoreViewSet, basename='cores')

urlpatterns = [path('', include(router.urls))]
