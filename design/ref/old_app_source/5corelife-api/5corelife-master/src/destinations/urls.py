from django.conf.urls import url

from .views import DestinationAPI

app_name = "destinations"

urlpatterns = [
    url('destinations/', DestinationAPI.as_view(), name="destinations"),
]
