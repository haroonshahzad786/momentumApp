from django.urls import path

from rest_framework.urlpatterns import format_suffix_patterns

from .views import FuneralAPI, FuneralDetailAPI

app_name = "funeral"

urlpatterns = [
    path('funeral', FuneralAPI.as_view(), name="funeral"),
    path('funeral/<int:funeral_id>', FuneralDetailAPI.as_view(), name="funeral-detail"),
]

urlpatterns = format_suffix_patterns(urlpatterns)
