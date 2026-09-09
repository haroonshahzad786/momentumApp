"""Trophy view."""

# Django REST Framework
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.mixins import ListModelMixin
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import GenericViewSet

# 5CoreLife
from habits.models import Habits
from trophy.models import Trophy, TrophyUser
from trophy.serializers import TrophySerializer, TrophyUserSerializer


class TrophyViewSet(ListModelMixin, GenericViewSet):
    """Trophy ViewSet"""

    permissions = (IsAuthenticated,)
    queryset = Trophy.objects.all()

    def get_serializer_class(self):
        """Return serializer based on action."""
        action_mappings = {'user': TrophyUserSerializer}
        return action_mappings.get(self.action, TrophySerializer)

    @action(detail=False)
    def user(self, request):
        """Return user's trophies."""
        user = request.user
        serializer_class = self.get_serializer_class()
        trophies_user = TrophyUser.objects.filter(user=user)
        data = serializer_class(trophies_user, many=True).data
        return Response(data, status=status.HTTP_200_OK)


def obtain_trophies_for_user(user, completed_destination_index=None):
    """
    Return a list with trophy/ies won for an user at the moment.
    If there is not any trophies won, the list returned will be empty.

    Parameters:
    user (User): An user
    completed_destination_index (int): If user arrived to destination.

    Returns:
    trophies_obtained: List with possibles trophies obtained
    """
    trophies_obtained = []
    trophies_to_check = Trophy.objects.all().difference(
        Trophy.objects.filter(pk__in=TrophyUser.objects.filter(user=user).values_list("trophy", flat=True))
    )
    give_trophy = False
    for trophy in trophies_to_check:
        give_trophy = (
            trophy.quantity_days > 0
            and user.user_profile.night_checks_in_row >= trophy.quantity_days
            or trophy.quantity_momentum > 0
            and user.user_profile.momentum >= trophy.quantity_momentum
            or trophy.reach_destination
            and completed_destination_index == trophy.reach_destination.index
            or trophy.quantity_habits > 0
            and Habits.objects.filter(user=user, formed=True).count() >= trophy.quantity_habits
        )

        if give_trophy:
            trophy_obtained = TrophyUser.objects.create(user=user, trophy=trophy)
            trophies_obtained.append(trophy_obtained)
    return trophies_obtained
