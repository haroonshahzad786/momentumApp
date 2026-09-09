from unittest.mock import patch

from config.testing.api_test_base import ApiTestBase
from users.tasks import delete_notification_status_pending_with_night_daily_check
from users.tasks import push_notification_deliveries


class TestTasks(ApiTestBase):
    @patch("users.tasks.delete_notification_status_pending_with_night_daily_check")
    def test_delete_notification_status_pending_with_night_daily_check_without_daily_check_user(
        self,
        delete_notification_status_pending_with_night_daily_check_without_daily_check_user_mock,
    ):
        self.create_notifications_to_delete_without_daily_check_user()
        delete_notification_status_pending_with_night_daily_check()
        delete_notification_status_pending_with_night_daily_check_without_daily_check_user_mock()

        self.assertTrue(
            delete_notification_status_pending_with_night_daily_check_without_daily_check_user_mock.called
        )

    @patch("users.tasks.delete_notification_status_pending_with_night_daily_check")
    def test_delete_notification_status_pending_with_night_daily_check_without_morning_check(
        self, delete_notification_status_pending_with_night_daily_check_mock
    ):
        self.create_notifications_to_delete_with_morningcheck_false()
        delete_notification_status_pending_with_night_daily_check()
        delete_notification_status_pending_with_night_daily_check_mock()

        self.assertTrue(
            delete_notification_status_pending_with_night_daily_check_mock.called
        )

    @patch("users.tasks.push_notification_deliveries")
    def test_push_notification_deliveries(self, push_notification_deliveries_mock):
        self.create_notifications()
        push_notification_deliveries()
        push_notification_deliveries_mock()

        self.assertTrue(push_notification_deliveries_mock.called)
