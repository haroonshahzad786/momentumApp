from django.urls import path

from rest_framework.urlpatterns import format_suffix_patterns

from .views import FearAPI, FearDetailAPI

app_name = "fears"

urlpatterns = [
    path('fears', FearAPI.as_view(), name="fears"),
    path('fears/<int:fear_id>', FearDetailAPI.as_view(), name="fears-detail"),
]

urlpatterns = format_suffix_patterns(urlpatterns)
