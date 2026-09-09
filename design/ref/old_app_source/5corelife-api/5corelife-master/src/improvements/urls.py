"""Improvements URLs."""

from django.urls import include, path
from rest_framework.routers import DefaultRouter

from improvements.views import ImprovementViewSet

router = DefaultRouter()
router.register(r'improvements', ImprovementViewSet, basename='improvements')

app_name = "improvements"
urlpatterns = [path('', include(router.urls))]
