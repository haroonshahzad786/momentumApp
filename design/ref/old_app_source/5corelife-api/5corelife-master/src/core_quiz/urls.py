"""Core Quiz urls."""

# Django
from django.urls import include, path
from rest_framework.routers import DefaultRouter

# 5CoreLife
from core_quiz.views import CoreQuizViewSet


router = DefaultRouter()
router.register(r'core-quiz', CoreQuizViewSet, basename='core_quiz')

app_name = "core_quiz"
urlpatterns = [path('', include(router.urls))]
