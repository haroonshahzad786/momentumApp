"""User tests."""
from datetime import datetime
from unittest.mock import patch

import pytz
from django.urls import reverse
from django.utils import timezone
from rest_framework import status

from config.testing.api_test_base import ApiTestBase
from users.models import RedemptionCode
from users.models import User


class UserAuthenticationAPITestCase(ApiTestBase):
    """User authentication API test case."""

    def test_signup(self):
        """Signup with a user"""
        data = {
            "email": "test05@test.com",
            "password": "pepe12345",
            "password_confirmation": "pepe12345",
            "tz_zone": "America/Fortaleza",
            "username": "test05",
        }
        response = self.client.post("/users/signup/", data=data)

        self.assertEqual(status.HTTP_201_CREATED, response.status_code)

    def test_login_with_error_authentication_return_user_none(self):
        """Login bad request. User no not authenticated"""
        data = {"username": "test", "password": "testpass"}
        response = self.client.post(reverse("users:users-login"), data=data)

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)

    @patch("users.serializers.authenticate")
    def test_login_error_authentication_return_user_without_user_profile(
        self, authenticate
    ):
        """Login bad request. User authenticate but not user_profile"""
        data = {"username": "test", "password": "testpass"}
        authenticate.return_value = self.user.username
        response = self.client.post(reverse("users:users-login"), data=data)

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)

    @patch("users.serializers.authenticate")
    def test_login_success(self, authenticate):
        """Login request success."""
        data = {"username": "test", "password": "testpass"}
        authenticate.return_value = self.user
        response = self.client.post(reverse("users:users-login"), data=data)

        self.assertEqual(status.HTTP_201_CREATED, response.status_code)

    def test_logout_success(self):
        """Logout request success."""
        response = self.client.get(reverse("users:users-logout"))

        self.assertEqual(status.HTTP_200_OK, response.status_code)

    def test_verify_with_raise_validation_error_invalid_code(self):
        self.user_code.expiration = datetime(
            2000, 11, 20, 20, 8, 7, 127325, tzinfo=pytz.UTC
        )
        self.user_code.save()
        data = {"code": self.user_code.code}
        response = self.client.post("/users/verify/", data=data)

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)

    def test_verify_success(self):
        data = {"code": self.user_code.code}
        response = self.client.post("/users/verify/", data=data)
        response_expected = {"message": "Congratulations, your account was validated!"}

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertEqual(response_expected, response.json())

    def test_forgot_password_with_raise_validation_error_invalid_email(self):
        data = {"email": "test_invalid@a.com"}
        response = self.client.post("/users/forgot-password/", data=data)

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)

    def test_forgot_password_success(self):
        data = {"email": "test@a.com"}
        response = self.client.post("/users/forgot-password/", data=data)
        response_expected = {"response": "Email sent."}

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertEqual(response_expected, response.json())

    def test_password_reset_with_raise_validation_error_password_not_match(self):
        data = {
            "email": "test@a.com",
            "password_confirmation": "pepe1234567",
            "password": "pepe123456",
            "code": self.user_code.code,
        }
        response = self.client.post("/users/password-reset/", data=data)

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)

    def test_password_reset(self):
        data = {
            "email": "test@a.com",
            "password_confirmation": "pepe123456",
            "password": "pepe123456",
            "code": self.user_code.code,
        }
        response = self.client.post("/users/password-reset/", data=data)
        response_expected = {"response": "Password updated."}

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertEqual(response_expected, response.json())

    def test_get_mantra(self):
        response = self.client.get("/users/mantra/")

        self.assertEqual(status.HTTP_200_OK, response.status_code)

    def test_put_mantra_with_raise_validation_error_mantra_missing(self):
        data = {"mantras": "invalid mantra"}
        response = self.client.put("/users/mantra/", data=data)

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)

    def test_put_mantra_when_value_is_none_raise_validation_error_mantra_required(self):
        data = {"mantra": ""}
        response = self.client.put("/users/mantra/", data=data)

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)

    def test_put_mantra_success(self):
        data = {"mantra": "test save mantra"}
        response = self.client.put("/users/mantra/", data=data)
        response_expected = data["mantra"]

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertEqual(response_expected, response.json()["mantra"])

    def test_abort_journey(self):
        self.user.user_profile.days_in_journey = 1
        self.user.user_profile.in_journey = True
        self.user.user_profile.save()
        self.user.user_profile.refresh_from_db()
        response = self.client.post("/users/abort-journey/")
        self.user.user_profile.refresh_from_db()
        response_expected = {
            "username": "test",
            "first_name": "Test",
            "last_name": "Test 2",
            "email": "test@a.com",
            "is_verified": False,
            "user_profile": {
                "credits": 0,
                "momentum": 0.0,
                "night_checks_in_row": 0,
                "last_night_check": None,
                "core_power_increase": 0,
                "days_in_journey": 0,
                "in_journey": False,
                "morning_check_time": "09:00",
                "night_check_time": "21:00",
                "pause": False,
                "notifications": True,
                "user_core_cap": 50,
                "actual_destination": "Space Station 1",
                "actual_destination_length": 1,
                "onboarding": False,
                "quiz": False,
                "cores_active": 1,
                "cores_available": 1,
                "score": 0,
                "code_redemption": False,
            },
        }

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertEqual("test", self.user.__str__())
        self.assertCountEqual(response_expected, response.json())
        self.assertEqual(0, self.user.user_profile.days_in_journey)
        self.assertFalse(self.user.user_profile.in_journey)

    def test_pause_journey(self):
        response = self.client.post("/users/pause-journey/")
        self.user.user_profile.refresh_from_db()
        response_expected = {
            "username": "test",
            "first_name": "Test",
            "last_name": "Test 2",
            "email": "test@a.com",
            "is_verified": False,
            "user_profile": {
                "credits": 0,
                "momentum": 0.0,
                "night_checks_in_row": 0,
                "last_night_check": None,
                "core_power_increase": 0,
                "days_in_journey": 0,
                "in_journey": False,
                "morning_check_time": "09:00",
                "night_check_time": "21:00",
                "pause": True,
                "notifications": True,
                "user_core_cap": 50,
                "actual_destination": "Space Station 1",
                "actual_destination_length": 1,
                "onboarding": False,
                "quiz": False,
                "cores_active": 1,
                "cores_available": 1,
                "score": 0,
                "code_redemption": False,
            },
        }

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertCountEqual(response_expected, response.json())
        self.assertTrue(self.user.user_profile.pause)

    def test_export_csv(self):
        response = self.client.get("/users/export-csv/")
        response_expected = [
            {
                "Username": "test",
                "Momentum": 0.0,
                "Mindset score": 0.0,
                "Mindset habits": "",
                "Relationships score": 0.0,
                "Relationships habits (current)": "",
                "Relationships habits (formed)": "",
                "Career & Finances": 0.0,
                "Career & Finances habits (current)": "",
                "Career & Finances habits (formed)": "",
                "Emotional Health": 0.0,
                "Emotional Health habits (current)": "",
                "Emotional Health habits (formed)": "",
                "Physical Health": 0.0,
                "Physical Health habits (current)": "",
                "Physical Health habits (formed)": "",
                "Captains log (each day with their 3 answers)": "",
                "Lists (unlocked)": "Name:Goals | Description: | Category:CORE | "
                "Destination:None\nName:Stress/Dwelling Killer | Description: | Category:SORTABLE "
                "| Destination:None\nName:Top 5 Fears To Tackle | Description: | "
                "Category:SORTABLE | Destination:None\nName:Top People In My Life | Description: "
                "| Category:CORE | Destination:None\nName:Messes To Clean | Description: | "
                "Category:SORTABLE | Destination:None\nName:Connections | Description: | "
                "Category:SORTABLE | Destination:None\nName:Bold To-do's | Description: | "
                "Category:SORTABLE | Destination:None\nName:Weaknesses | Description: | "
                "Category:SORTABLE | Destination:None\nName:Passions | Description: | "
                "Category:SORTABLE | Destination:None\nName:Strengths | Description: | "
                "Category:SORTABLE | Destination:None\nName:Daily Routine | Description: | "
                "Category:SORTABLE | Destination:None\nName:Gratitude List | Description: | "
                "Category:SORTABLE | Destination:None\nName:One-Time-Actions | Description: | "
                "Category:CORE | Destination:None\nName:Back to the future | Description: | "
                "Category:CORE | Destination:None",
            }
        ]

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertEqual(response_expected, response.data)

    def test_code_redemption_with_raise_validation_error_user_has_redeemed_code(self):
        self.code_redemption.redeemed_by = self.user
        self.code_redemption.save()
        self.code_redemption.refresh_from_db()
        data = {"code": "12345678"}
        response = self.client.post("/users/code-redemption/", data=data)

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)

    def test_code_redemption_with_raise_validation_error_code_already_used(self):
        user_with_code_redemption = User.objects.create(
            first_name="Test code redemption",
            last_name="used",
            email="test1@a.com",
            username="test1",
            password="testpass",
        )
        code_redemption = RedemptionCode(
            redeemed_by=user_with_code_redemption,
            code="01234567",
            claimed_date=timezone.now(),
        )
        code_redemption.save()
        data = {"code": "01234567"}
        response = self.client.post("/users/code-redemption/", data=data)

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)

    def test_code_redemption_with_raise_validation_error_code_not_found(self):
        self.code_redemption.delete()
        data = {"code": "12345678"}
        response = self.client.post("/users/code-redemption/", data=data)

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)

    def test_code_redemption(self):
        data = {"code": "12345678"}
        response = self.client.post("/users/code-redemption/", data=data)

        self.assertEqual(status.HTTP_200_OK, response.status_code)

    def test_leaderboard(self):
        response = self.client.get("/users/leaderboard/")
        response_expected = [
            {
                "username": "test",
                "score": 0,
                "armor": None,
                "destination": "Space Station 1",
            }
        ]

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertCountEqual(response_expected, response.json())

    def test_leaderboard_queryset_until_nineteen_position(self):
        for i in range(1, 21):
            user = User.objects.create(
                first_name="Test",
                last_name=str(i),
                email="test%s@a.com" % i,
                username="test%s" % i,
                password="testpass",
            )
            user.user_profile.score = i
            user.user_profile.save()

        response = self.client.get("/users/leaderboard/")
        response_expected = {
            "username": "test",
            "score": 0,
            "armor": None,
            "destination": "Space Station 1",
        }

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertEqual(20, len(response.json()))
        self.assertEqual(response_expected, response.json()[19])
