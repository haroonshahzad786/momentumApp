from rest_framework import status

from config.testing.api_test_base import ApiTestBase
from core_quiz.models import CoreQuiz


class TestCoreQuiz(ApiTestBase):
    def test_core_quiz_create_without_body_return_bad_request(self):
        response = self.client.post("/core-quiz/")

        self.assertEqual(status.HTTP_400_BAD_REQUEST, response.status_code)

    def test_core_quiz_create(self):
        data = {"core": "MINDSET", "points": 4}
        response = self.client.post("/core-quiz/", data=data)

        self.assertEqual(status.HTTP_201_CREATED, response.status_code)

    def test_core_quiz_get_queryset(self):
        response = self.client.get("/core-quiz/")
        response_expected = [{"core": "MINDSET", "points": 3}]

        self.assertEqual(status.HTTP_200_OK, response.status_code)
        self.assertCountEqual(response_expected, response.json())

    def test_model_str(self):
        core_quiz = CoreQuiz.objects.get(user=self.user).__str__()
        return_core_quiz = "test | MINDSET | 3"

        self.assertEqual(return_core_quiz, core_quiz)
