"""Quests URLs."""

# Django
from django.urls import include, path
from rest_framework.routers import DefaultRouter

# 5CoreLife
from quests.views import UserQuestsViewSet

router = DefaultRouter()
router.register(r'quests', UserQuestsViewSet, basename='quests')

app_name = "quests"
urlpatterns = [path('', include(router.urls))]
