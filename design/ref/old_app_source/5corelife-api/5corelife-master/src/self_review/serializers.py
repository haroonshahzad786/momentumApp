from rest_framework import serializers

from .models import SelfReview, Answer


class AnswerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Answer
        fields = ('id', 'answer', 'question_number')


class SelfReviewSerializer(serializers.ModelSerializer):
    answers = AnswerSerializer(many=True)

    class Meta:
        model = SelfReview
        fields = ('id', 'date', "answers")
