from rest_framework import status

from bonus.commons import consume_bonus
from bonus.models import Bonus
from bonus.models import BonusUser
from config.testing.api_test_base import ApiTestBase


class TestBonusCommons(ApiTestBase):
    def test_consume_bonus(self):
        result = consume_bonus(
            user=self.user, bonus_name="One-time - Negate/Skip check-in"
        )
        result_expected = 1

        self.assertEqual(result_expected, result)

    def test_bonus_users(self):
        response = self.client.get("/bonus/user/")
        response_count_expected = 1
        bonus_user_str_expected = "One-time - Negate/Skip check-in | test"
        bonus_str_expected = "One-time - Negate/Skip check-in"

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertEqual(response_count_expected, len(response.json()))
        self.assertEqual(
            bonus_user_str_expected,
            BonusUser.objects.get(user_id=self.user.pk).__str__(),
        )
        self.assertEqual(
            bonus_str_expected,
            Bonus.objects.get(name="One-time - Negate/Skip check-in").__str__(),
        )

    def test_bonus_buy_with_raise_name_field_is_required(self):
        data = {"bonus": "test bonus"}
        response = self.client.post("/bonus/buy/", data=data)
        response_expected = {"name": ["This field is required."]}

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)
        self.assertEqual(response_expected, response.json())

    def test_bonus_buy_with_raise_validation_error_bonus_not_exists(self):
        data = {"name": "test bonus"}
        response = self.client.post("/bonus/buy/", data=data)
        response_expected = {"name": ["Bonus with name test bonus does not exist."]}

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)
        self.assertEqual(response_expected, response.json())

    def test_bonus_buy_with_raise_validation_error_insufficient_credit(self):
        data = {"name": "One-time - Negate/Skip check-in"}
        response = self.client.post("/bonus/buy/", data=data)
        response_expected = {"credits": ["Insufficient credit"]}

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)
        self.assertEqual(response_expected, response.json())

    def test_bonus_buy_with_raise_validation_error_user_has_this_bonus(self):
        self.user.user_profile.credits = 500
        self.user.user_profile.save()
        self.user.user_profile.refresh_from_db()
        data = {"name": "One-time - Negate/Skip check-in"}
        response = self.client.post("/bonus/buy/", data=data)
        self.user.user_profile.refresh_from_db()
        response_expected = {"bonus": ["The user already has this bonus."]}

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)
        self.assertEqual(response_expected, response.json())

    def test_bonus_buy_success(self):
        self.user.user_profile.credits = 300
        self.user.user_profile.save()
        self.user.user_profile.refresh_from_db()
        data = {"name": "One-time - Increase minimum core score for day"}
        response = self.client.post("/bonus/buy/", data=data)
        self.user.user_profile.refresh_from_db()
        response_count_expected = 2

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertEqual(response_count_expected, len(response.json()))
