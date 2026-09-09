"""Inspirations urls."""

from django.urls import path
from django.urls import include
from rest_framework.routers import DefaultRouter

# 5Corelife
from inspirations.views import InspirationsViewSet


router = DefaultRouter()
router.register(r'inspirations', InspirationsViewSet, basename='inspirations')

app_name = "inspirations"
urlpatterns = [path('', include(router.urls))]
