"""Mantras urls."""

from django.urls import path
from django.urls import include
from rest_framework.routers import DefaultRouter
import mantras.views as mantras_views

router = DefaultRouter()
router.register(r'mantras', mantras_views.MantrasViewSet, basename='mantras')

app_name = "users"
urlpatterns = [
    path('', include(router.urls))
]
