"""Trophies URLs."""

# Django
from django.urls import include, path
from rest_framework.routers import DefaultRouter

# 5CoreLife
from trophy.views import TrophyViewSet

router = DefaultRouter()
router.register(r'trophies', TrophyViewSet, basename='trophies')

app_name = "trophy"
urlpatterns = [path('', include(router.urls))]
