"""CockpitList urls."""

# Django
from django.urls import include, path
from rest_framework.routers import DefaultRouter

# 5CoreLife
from cockpit_list.views import CockpitListViewSet


router = DefaultRouter()
router.register(r'cockpit-list', CockpitListViewSet, basename='cockpit_list')

app_name = "cockpit_list"
urlpatterns = [path('', include(router.urls))]
