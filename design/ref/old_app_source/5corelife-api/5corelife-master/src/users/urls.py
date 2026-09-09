"""Users urls."""

from django.urls import path
from django.urls import include
from rest_framework.routers import DefaultRouter
import users.views as user_views

router = DefaultRouter()
router.register(r'users', user_views.UserViewSet, basename='users')

app_name = "users"
urlpatterns = [
    path('', include(router.urls)),
]
