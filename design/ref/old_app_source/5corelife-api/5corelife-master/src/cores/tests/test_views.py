from rest_framework import status

from config.testing.api_test_base import ApiTestBase
from cores.models import CoreUser
from cores.strings import max_core_count_reached
from destinations.strings import destination_not_exists
from improvements.models import Improvement
from improvements.models import ImprovementUser


class TestCores(ApiTestBase):
    def test_models_core_user_return_str(self):
        core_user = CoreUser(user=self.user, core_string="test core")
        core_user.save()
        expected_core_user = "test test core False"

        self.assertEqual(
            expected_core_user, CoreUser.objects.get(core_string="test core").__str__()
        )

    def test_model_core_user_add_core_power_with_improvement_user(self):
        improvement_for_user = Improvement(
            name="Rare",
            cost=250,
            probability_reward=15,
            improvement_type="THRUSTER",
            order=1,
            core_power_multiplier=10,
        )
        improvement_for_user.save()
        improvement_user = ImprovementUser(
            user=self.user, improvement=improvement_for_user, equipped=True
        )
        improvement_user.save()
        core_user = CoreUser(user=self.user, core_string="test core")
        core_user.save()
        core_user.add_core_power(power=55, user_profile=self.user.user_profile)
        result_expected_core_user_power = 50

        self.assertTrue(
            ImprovementUser.objects.filter(
                user=self.user,
                improvement__improvement_type="THRUSTER",
                improvement__core_power_multiplier__gt=0,
                equipped=True,
            ).first()
        )
        self.assertEqual(result_expected_core_user_power, core_user.power)

    def test_model_core_user_add_core_power_when_new_power_more_than_user_profile_user_core_cap(
        self,
    ):
        core_user = CoreUser(user=self.user, core_string="test core")
        core_user.save()
        core_user.add_core_power(power=55, user_profile=self.user.user_profile)
        result_expected_core_user_power = 50

        self.assertFalse(
            ImprovementUser.objects.filter(
                user=self.user,
                improvement__improvement_type="THRUSTER",
                improvement__core_power_multiplier__gt=0,
                equipped=True,
            ).first()
        )
        self.assertEqual(result_expected_core_user_power, core_user.power)

    def test_model_core_user_add_core_power_when_new_power_less_than_user_profile_user_core_cap(
        self,
    ):
        core_user = CoreUser(user=self.user, core_string="test core")
        core_user.save()
        core_user.add_core_power(power=10, user_profile=self.user.user_profile)
        result_expected_core_user_power = 30

        self.assertFalse(
            ImprovementUser.objects.filter(
                user=self.user,
                improvement__improvement_type="THRUSTER",
                improvement__core_power_multiplier__gt=0,
                equipped=True,
            ).first()
        )
        self.assertEqual(result_expected_core_user_power, core_user.power)

    def test_cores_list(self):
        response = self.client.get("/cores/")
        response_expected = [
            "EMOTIONAL_HEALTH",
            "RELATIONSHIPS",
            "CAREER_FINANCES",
            "MINDSET",
            "PHYSICAL_HEALTH",
        ]

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertEqual(response_expected, response.json())

    def test_get_user_cores(self):
        response = self.client.get("/cores/user/")
        response_expected = [
            {
                "user": self.user.pk,
                "core_string": "PHYSICAL_HEALTH",
                "enabled": False,
                "core_power": 0,
            },
            {
                "user": self.user.pk,
                "core_string": "MINDSET",
                "enabled": True,
                "core_power": 0,
            },
            {
                "user": self.user.pk,
                "core_string": "CAREER_FINANCES",
                "enabled": False,
                "core_power": 0,
            },
            {
                "user": self.user.pk,
                "core_string": "RELATIONSHIPS",
                "enabled": False,
                "core_power": 0,
            },
            {
                "user": self.user.pk,
                "core_string": "EMOTIONAL_HEALTH",
                "enabled": False,
                "core_power": 0,
            },
        ]

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertEqual(response_expected, response.json())

    def test_post_core_user_with_raise_validation_error_core_invalid(self):
        data = {"core": "MINDSETS1"}
        response = self.client.post("/cores/user/", data=data)
        response_expected = {"core": ["Core invalid."]}

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)
        self.assertCountEqual(response_expected, response.json())

    def test_post_core_user_with_raise_validation_error_user_destination_not_exists(
        self,
    ):
        self.user.user_profile.destination_index = 0
        self.user.user_profile.save()
        self.user.user_profile.refresh_from_db()
        data = {"core": "MINDSET"}
        response = self.client.post("/cores/user/", data=data)
        response_expected = {"user": destination_not_exists}

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)
        self.assertCountEqual(response_expected, response.json())

    def test_post_core_user_with_raise_validation_error_user_max_core_count_reached(
        self,
    ):
        data = {"core": "MINDSET"}
        response = self.client.post("/cores/user/", data=data)
        response_expected = {"user": max_core_count_reached}

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)
        self.assertCountEqual(response_expected, response.json())

    def test_post_core_user_success(self):
        self.user.user_profile.destination_index = 3
        self.user.user_profile.save()
        self.user.user_profile.refresh_from_db()
        data = {"core": "MINDSET"}
        response = self.client.post("/cores/user/", data=data)
        response_expected = {
            "user": self.user.pk,
            "core_string": "MINDSET",
            "enabled": True,
            "core_power": 0,
        }

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertCountEqual(response_expected, response.json())
