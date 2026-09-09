from json import loads
from datetime import date


from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import SelfReview, Answer
from self_review import strings as strs
from .serializers import SelfReviewSerializer
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

permission_classes = (IsAuthenticated,)


class SelfReviewAPI(APIView):
    """Self Review API"""
    permission_classes = permission_classes

    @swagger_auto_schema(responses={201: SelfReviewSerializer}, request_body=openapi.Schema(type=openapi.TYPE_OBJECT, properties={'answers': openapi.Schema(type=openapi.TYPE_STRING)}))
    def post(self, request):
        """Self Review API create.
        El campo answer tiene que ser un array de strings como el siguiente ['I am ok', 'This is awesome', 'I am ready to start']"""
        answers = request.data.get('answers', None)
        if answers is None:
            return Response({"error": strs.missing_parameter_answers}, status=status.HTTP_400_BAD_REQUEST)
        answers = loads(answers)
        if SelfReview.objects.filter(date=date.today(), user=request.user).exists():
            return Response({"error": strs.cannot_create_self_review_already_exists_today}, status=status.HTTP_403_FORBIDDEN)
        self_review = SelfReview(date=date.today(), user=request.user)
        self_review.save()
        Answer.objects.bulk_create([Answer(question_number=answer_number, self_review=self_review,
                                           answer=answers[answer_number])
                                    for answer_number in range(0, len(answers))])
        return Response(SelfReviewSerializer(self_review).data, status=status.HTTP_201_CREATED)

    @swagger_auto_schema(responses={200: SelfReviewSerializer})
    def get(self, request):
        """ Captain's log"""
        answers = SelfReviewSerializer(SelfReview.objects.filter(user=request.user), many=True)
        return Response(answers.data)
