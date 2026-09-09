from django.urls import path

from rest_framework.urlpatterns import format_suffix_patterns

from .views import view_report

app_name = "reports"

urlpatterns = [
    path('', view_report, name="index"),
]

urlpatterns = format_suffix_patterns(urlpatterns)
