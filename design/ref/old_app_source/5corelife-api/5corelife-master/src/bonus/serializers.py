"""Bonus Serializers."""

from django.utils import timezone
from rest_framework import serializers

from bonus.models import Bonus, BonusUser


class BonusSerializer(serializers.ModelSerializer):
    class Meta:
        model = Bonus
        fields = ('id', 'name', 'cost', 'description')


class BonusUserSerializer(serializers.ModelSerializer):
    bonus = BonusSerializer()

    class Meta:
        model = BonusUser
        fields = ('active', 'bonus', 'used', 'date_active')


class BuyBonusSerializer(serializers.Serializer):
    name = serializers.CharField()

    def validate(self, attrs):
        name = attrs.get('name')

        bonus = Bonus.objects.filter(name__iexact=name).first()
        user = self.context.get('user')

        if not bonus:
            raise serializers.ValidationError({'name': f'Bonus with name {name} does not exist.'})

        if bonus.cost > user.user_profile.credits:
            raise serializers.ValidationError({'credits': 'Insufficient credit'})

        bonus_user = BonusUser.objects.filter(user=user, bonus=bonus, active=True)
        if bonus_user:
            raise serializers.ValidationError({'bonus': 'The user already has this bonus.'})

        self.context['bonus'] = bonus
        return attrs

    def create(self, attrs):
        bonus = self.context.get('bonus')
        user = self.context.get('user')

        user.user_profile.credits -= bonus.cost
        user.user_profile.save()
        bonus_user, _ = BonusUser.objects.get_or_create(bonus=bonus, user=user)
        bonus_user.active = True
        bonus_user.date_active = timezone.now().date()
        bonus_user.save()

        return bonus_user
