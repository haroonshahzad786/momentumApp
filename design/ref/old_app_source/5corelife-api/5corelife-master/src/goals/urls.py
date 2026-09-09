"""Goals urls."""

# Django
from django.urls import include, path
from rest_framework.routers import DefaultRouter

# 5CoreLife
from goals.views import GoalUserViewSet

router = DefaultRouter()
router.register(r'goals', GoalUserViewSet, basename='goals')

app_name = "goals"
urlpatterns = [path('', include(router.urls))]
