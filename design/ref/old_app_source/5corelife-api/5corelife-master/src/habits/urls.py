"""Habits urls."""

# Django
from django.urls import include, path
from rest_framework.routers import DefaultRouter

# 5CoreLife
from habits.views import HabitsViewSet


router = DefaultRouter()
router.register(r'habits', HabitsViewSet, basename='habits')

app_name = "habits"
urlpatterns = [path('', include(router.urls))]
