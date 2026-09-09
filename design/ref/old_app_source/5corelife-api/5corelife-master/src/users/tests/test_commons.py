from config.testing.api_test_base import ApiTestBase
from goals.models import GoalUser
from users.commons import add_credits


class AddCreditsTestCase(ApiTestBase):
    def test_add_credits(self):
        self.create_user_to_add_credits()
        user_expected = add_credits(self.user)

        self.user.user_profile.refresh_from_db()
        goals_user = GoalUser.objects.filter(user=self.user)

        self.assertEqual(
            self.user.user_profile.credits, user_expected.user_profile.credits
        )
        self.assertEqual(self.user.user_profile.score, user_expected.user_profile.score)

        goal_complete_with_score_expected = 25
        goal_no_complete_with_score_expected = 0
        for goal in goals_user:
            if not goal.completed:
                self.assertEqual(goal.score, goal_complete_with_score_expected)
            else:
                self.assertEqual(goal.score, goal_no_complete_with_score_expected)
