from django.urls import path

from rest_framework.urlpatterns import format_suffix_patterns

from .views import SelfReviewAPI

app_name = "self_review"

urlpatterns = [
    path('self-review', SelfReviewAPI.as_view(), name="self-review"),
]

urlpatterns = format_suffix_patterns(urlpatterns)
