"""Missions URLs."""

# Django
from django.urls import include, path
from rest_framework.routers import DefaultRouter

# 5CoreLife
from mission.views import UserMissionViewSet

router = DefaultRouter()
router.register(r'missions', UserMissionViewSet, basename='missions')

app_name = "missions"
urlpatterns = [path('', include(router.urls))]
