"""Bonus URLs."""

from django.urls import include, path
from rest_framework.routers import DefaultRouter

from bonus.views import BonusViewSet

router = DefaultRouter()
router.register(r'bonus', BonusViewSet, basename='bonus')

app_name = 'bonus'
urlpatterns = [path('', include(router.urls))]
