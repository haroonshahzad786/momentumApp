"""Habits filters."""

# Django filters
from django_filters import rest_framework as filters

# Models
from habits.models import DailyCheck


class HabitFilterSet(filters.FilterSet):
    """Habit filters."""

    core = filters.CharFilter(method='search_by_core')
    last = filters.BooleanFilter(method='search_by_last')
    formed = filters.BooleanFilter(method='search_by_formed')

    def search_by_core(self, queryset, name, value):
        """Search by core."""
        if value:
            queryset = queryset.filter(core=value)
        return queryset

    def search_by_formed(self, queryset, name, value):
        """Search by formed."""
        if value:
            queryset = queryset.filter(formed=value)
        return queryset

    def search_by_last(self, queryset, name, value):
        """Obtain the latest habits used."""
        core = self.request.GET.get('core', None)
        user = self.request.user
        dailycheck_last = DailyCheck.objects.filter(user=user).order_by('-created')
        if core:
            dailycheck_last = dailycheck_last.filter(core=core)

        if dailycheck_last:
            habits = []
            for daily_habit in dailycheck_last.first().checkdaily.all():
                habits.append(daily_habit.habit.pk)
            queryset = queryset.filter(pk__in=habits)
        else:
            queryset = queryset.none()
        return queryset
