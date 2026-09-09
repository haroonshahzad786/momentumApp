"""Habits view."""

# Django
import logging

from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.mixins import (
    CreateModelMixin,
    DestroyModelMixin,
    ListModelMixin,
    RetrieveModelMixin,
    UpdateModelMixin,
)
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import GenericViewSet

# 5CoreLife
from bonus.models import BonusUser
from bonus.strings import INCREASE_CORE_POWER_DAY, INCREASE_MOMENTUM_JOURNEY
from cockpit_list.models import CockpitList
from destinations.models import Destination, DestinationUser
from habits.filters import HabitFilterSet
from habits.models import DailyCheck, DailyHabits, Habits
from habits.serializers import (
    DailyCheckDeleteSerializer,
    DailyCheckModelSerializer,
    DailyCheckSerializer,
    HabitsModelSerializer,
    MorningCheckSerializer,
    NightCheckSerializer,
)
from improvements.models import Improvement, ImprovementUser
from mission.commons import MISSIONS, obtain_mission
from mission.models import UserMission
from quests.commons import check_validation_quest, obtain_quest
from quests.models import UserQuest
from rewards.views import obtain_reward
from trophy.serializers import TrophyUserSerializer
from trophy.views import obtain_trophies_for_user
from users.commons import add_credits
from users.permissions import IsObjectOwner

logger = logging.getLogger(__name__)


class HabitsViewSet(
    CreateModelMixin,
    ListModelMixin,
    RetrieveModelMixin,
    UpdateModelMixin,
    DestroyModelMixin,
    GenericViewSet,
):
    """Habits View Set"""

    queryset = Habits.objects.all()
    permissions = (IsAuthenticated, IsObjectOwner)
    filter_backends = (DjangoFilterBackend,)
    filterset_class = HabitFilterSet

    def get_queryset(self):
        """Return the user's habits."""
        return self.queryset.filter(user=self.request.user)

    def get_serializer_class(self):
        """Return serializer based on action."""
        action_mappings = {
            "morning_check": MorningCheckSerializer,
            "night_check": NightCheckSerializer,
            "get_status": DailyCheckModelSerializer,
            "list_dailychecks": DailyCheckModelSerializer,
            "delete_check": DailyCheckDeleteSerializer,
        }
        return action_mappings.get(self.action, HabitsModelSerializer)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        data = serializer.data
        if "formed" in request.data:
            data["trophies"] = TrophyUserSerializer(
                obtain_trophies_for_user(self.request.user), many=True
            ).data

        if getattr(instance, "_prefetched_objects_cache", None):
            instance._prefetched_objects_cache = {}

        return Response(data)

    @action(url_path="morning-check", detail=False, methods=["post"])
    def morning_check(self, request):
        """Morning check."""
        user = request.user
        user_profile = user.user_profile
        serializer_class = self.get_serializer_class()
        data = request.data if request.data else None
        serializer = serializer_class(data=data, many=True, context={"user": user})
        serializer.is_valid(raise_exception=True)
        dailychecks = serializer.save()

        # Bonus check
        today = timezone.now().date()
        BonusUser.objects.filter(
            user=user, bonus__name=INCREASE_CORE_POWER_DAY, active=True
        ).exclude(date_active=today).update(active=False, date_active=None, used=True)
        # Quest and mission
        quest_assigned = None
        mission_obtained = None
        if not user_profile.in_journey:
            user_profile.in_journey = True
            user_profile.save()
            quest_assigned = obtain_quest(user)
        else:
            quest_assigned = UserQuest.objects.get(active=True, user=user)
            # Missions are received every 3 days, starting on day 2
            # Missions should not be assigned on the last of a Journey
            current_destination = Destination.objects.filter(
                index=user_profile.destination_index
            ).first()
            days_in_journey = user.user_profile.days_in_journey
            if (
                days_in_journey - 2
            ) % 3 == 0 and days_in_journey != current_destination.length:
                mission_obtained = obtain_mission(user)

        # Credits
        user = add_credits(user)

        context = {
            "user_profile": user.user_profile,
            "quest": quest_assigned,
            "mission": mission_obtained,
            "trophies": obtain_trophies_for_user(user),
        }
        data = DailyCheckSerializer({"dailychecks": dailychecks}, context=context).data
        return Response(data, status=status.HTTP_201_CREATED)

    @action(url_path="night-check", detail=False, methods=["post"])
    def night_check(self, request):
        """Night check."""
        try:
            completed_destination_index = None
            user = request.user
            serializer_class = self.get_serializer_class()
            data = request.data if request.data else None
            serializer = serializer_class(data=data, many=True, context={"user": user})
            serializer.is_valid(raise_exception=True)
            dailychecks = serializer.save()

            # Credits
            user = add_credits(user)
            logger.info(f"after user_profile: {user}")

            # Days in Journey and Night checks in row
            today = timezone.now().date()
            last_night_check = user.user_profile.last_night_check
            user.user_profile.last_night_check = today
            if last_night_check is None:
                user.user_profile.night_checks_in_row = 1
            else:
                day_diff = today - last_night_check
                if day_diff.days == 1:
                    user.user_profile.night_checks_in_row += 1
                else:
                    user.user_profile.night_checks_in_row = 1
            user.user_profile.days_in_journey += 1
            user.user_profile.save()

            # Next destination: the user has passed the half of the journey
            destination_queryset = Destination.objects.filter(
                index=user.user_profile.destination_index
            )
            destination = destination_queryset.first()
            journey_success_status = None
            endless = Destination.objects.order_by("-index").first()
            if destination == endless:
                if user.user_profile.momentum != endless.momentum_required:
                    # Insufficient momentum
                    user.user_profile.in_journey = False
                    user.user_profile.days_in_journey = 0
                    journey_success_status = False
            elif user.user_profile.days_in_journey >= destination.length / 2:
                if user.user_profile.momentum >= destination.momentum_required:
                    if user.user_profile.days_in_journey == destination.length:
                        # arrived at destination
                        completed_destination_index = (
                            user.user_profile.destination_index
                        )
                        user.user_profile.in_journey = False
                        logger.info(
                            f"before add_credits user_profile: {user.user_profile}"
                        )
                        add_credits(
                            user,
                            multiplier=user.user_profile.days_in_journey,
                            credits_number=50,
                        )
                        user.user_profile.days_in_journey = 0
                        user.user_profile.destination_index = destination.index + 1
                        # The new next destination
                        actual_destination = Destination.objects.filter(
                            index=user.user_profile.destination_index
                        ).first()
                        DestinationUser.objects.create(
                            user=user, destination=actual_destination
                        )
                        journey_success_status = True
                        # Improvements
                        if not ImprovementUser.objects.filter(
                            improvement__destination__index=user.user_profile.destination_index,
                            user=user,
                        ).exists():
                            improvement = Improvement.objects.filter(
                                destination__index=user.user_profile.destination_index
                            ).first()
                            if improvement:
                                ImprovementUser.objects.create(
                                    user=user, improvement=improvement
                                )
                        # Bonus
                        BonusUser.objects.filter(
                            user=user,
                            bonus__name=INCREASE_MOMENTUM_JOURNEY,
                            active=True,
                        ).update(active=False, date_active=None, used=True)
                        # Cockpit List
                        CockpitList.objects.filter(
                            user=user, destination=actual_destination
                        ).update(enabled=True)
                else:
                    # Insufficient momentum
                    user.user_profile.in_journey = False
                    user.user_profile.days_in_journey = 0
                    journey_success_status = False
                user.user_profile.save()

            user.refresh_from_db()
            journey_status = None
            if not user.user_profile.in_journey:
                journey_status = "Completed" if journey_success_status else "Failed"

            trophies = obtain_trophies_for_user(user, completed_destination_index)
            quest = check_validation_quest(user)
            # Search in dict for the name of the function, based on the the
            # name of the mission assigned to the user. After that, it invokes it.
            # The returned object it's the UserMission assigned with the completion status
            mission = None
            mission_success = False
            user_mission = UserMission.objects.filter(active=True, user=user).exclude(
                mission__code_name="comfort_zone"
            )
            if user_mission.exists():
                code_name = user_mission.first().mission.code_name
                mission = MISSIONS[code_name](user)
                mission_success = mission.success

            reward = None
            if quest.success or mission_success:
                reward = obtain_reward(user)

            context = {
                "user_profile": user.user_profile,
                "journey_status": journey_status,
                "quest": quest,
                "mission": mission,
                "trophies": trophies,
                "reward": reward,
            }
            data = DailyCheckSerializer(
                {"dailychecks": dailychecks}, context=context
            ).data
            return Response(data, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Error doing night check{e}")

    @action(detail=False, url_path="dailychecks")
    def list_dailychecks(self, request):
        """User's dailychecks list."""
        user = request.user
        serializer_class = self.get_serializer_class()
        dailychecks = DailyCheck.objects.filter(user=user)
        data = serializer_class(dailychecks, many=True).data
        return Response(data)

    @action(url_path="get-status", detail=False)
    def get_status(self, request):
        """Returns the today dailycheck for a core."""
        core = request.query_params.get("core", None)
        today = timezone.now().date()
        dailycheck = DailyCheck.objects.filter(
            user=request.user, core=core, created__startswith=today
        ).first()
        if not dailycheck:
            data = {
                "open": True,
                "morningcheck": False,
                "nightcheck": False,
                "core": core,
            }
        else:
            serializer_class = self.get_serializer_class()
            data = serializer_class(dailycheck).data
        return Response(data, status=status.HTTP_200_OK)

    @action(url_path="delete-check", detail=False, methods=["delete"])
    def delete_check(self, request):
        """Delete a dailycheck."""
        serializer_class = self.get_serializer_class()
        serializer = serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.data
        DailyHabits.objects.filter(
            habit=data.get("habit"), dailycheck=data.get("dailycheck")
        ).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
