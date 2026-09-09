from django.urls import path

from rest_framework.urlpatterns import format_suffix_patterns

from .views import TopPeopleAPI, TopPeopleDetailAPI

app_name = "top_people"

urlpatterns = [
    path('top-people', TopPeopleAPI.as_view(), name="top-people"),
    path('top-people/<int:top_people_id>', TopPeopleDetailAPI.as_view(), name="top-people-detail"),
]

urlpatterns = format_suffix_patterns(urlpatterns)
