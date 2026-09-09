from django.conf import settings
from django.conf.urls import url
from django.conf.urls.static import static
from django.contrib import admin
from django.contrib.staticfiles.urls import staticfiles_urlpatterns
from django.urls import include, path
from django.views import defaults as default_views
from drf_yasg import openapi
from drf_yasg.views import get_schema_view
from rest_framework import permissions

admin.site.site_header = '5CoreLife Admin Panel'
admin.site.site_title = '5CoreLife'

schema_view = get_schema_view(
    openapi.Info(
        title="api_momentum",
        default_version='v1',
        description="API Momentum",
    ),
    permission_classes=(permissions.IsAuthenticatedOrReadOnly,),
    public=False,
)

urlpatterns = [
    # Django Admin, use {% url 'admin:index' %}
    path(settings.ADMIN_URL, admin.site.urls),
    # Report
    path('reports', include('reports.urls')),
    # Swagger
    url(r'^swagger(?P<format>\.json|\.yaml)$', schema_view.without_ui(cache_timeout=0), name='schema-json'),
    url(r'^swagger/$', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    # User management
    path('', include(('users.urls', 'users'), namespace='users')),
    # Mantras
    path('', include(('mantras.urls', 'mantras'), namespace='mantras')),
    # Inspirations
    path('', include(('inspirations.urls', 'inspirations'), namespace='inspirations')),
    # Habits
    path('', include(('habits.urls', 'habits'), namespace='habits')),
    # Destinations
    path('', include(('destinations.urls', 'destinations'), namespace='destination')),
    # Top People
    path('', include(('top_people.urls', 'top_people'), namespace='top-people')),
    # Fears
    path('', include(('fears.urls', 'fears'), namespace='fears')),
    # Funeral
    path('', include(('funeral.urls', 'funeral'), namespace='funeral')),
    # Self review
    path('', include(('self_review.urls', 'self_review'), namespace='self_review')),
    # Trophy
    path('', include(('trophy.urls', 'trophy'), namespace='trophy')),
    # Cores
    path('', include(('cores.urls', 'cores'), namespace='cores')),
    # Bonus
    path('', include(('bonus.urls', 'bonus'), namespace='bonus')),
    # Improvements
    path('', include(('improvements.urls', 'bonus'), namespace='improvements')),
    # Missions
    path('', include(('mission.urls', 'missions'), namespace='missions')),
    # Quests
    path('', include(('quests.urls', 'quests'), namespace='quests')),
    # CockpitList
    path('', include(('cockpit_list.urls', 'cockpit_list'), namespace='cockpit_list')),
    # CoreQuiz
    path('', include(('core_quiz.urls', 'core_quiz'), namespace='core_quiz')),
    # Goals
    path('', include(('goals.urls', 'goals'), namespace='goals')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
if settings.DEBUG:
    # Static file serving when using Gunicorn + Uvicorn for local web socket development
    urlpatterns += staticfiles_urlpatterns()


if settings.DEBUG:
    # This allows the error pages to be debugged during development, just visit
    # these url in browser to see how these error pages look like.
    urlpatterns += [
        path(
            "400/",
            default_views.bad_request,
            kwargs={"exception": Exception("Bad Request!")},
        ),
        path(
            "403/",
            default_views.permission_denied,
            kwargs={"exception": Exception("Permission Denied")},
        ),
        path(
            "404/",
            default_views.page_not_found,
            kwargs={"exception": Exception("Page not Found")},
        ),
        path("500/", default_views.server_error),
    ]
