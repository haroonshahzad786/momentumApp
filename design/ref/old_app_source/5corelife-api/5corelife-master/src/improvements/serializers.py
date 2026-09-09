from rest_framework import serializers

from .models import Improvement, ImprovementUser


class ImprovementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Improvement
        fields = (
            'name',
            'cost',
            'probability_reward',
            'destination',
            'improvement_type',
            'default',
            'order',
            'bonus_core_cap',
            'core_power_multiplier',
        )


class ImprovementUserSerializer(serializers.ModelSerializer):
    improvement = ImprovementSerializer()

    class Meta:
        model = ImprovementUser
        fields = ('improvement', 'equipped')


class BuyImprovementSerializer(serializers.Serializer):
    name = serializers.CharField()
    improvement_type = serializers.CharField()

    def validate(self, attrs):
        name = attrs.get('name')
        improvement_type = attrs.get('improvement_type')
        user = self.context.get('user')

        improvement = Improvement.objects.filter(name__iexact=name, improvement_type__iexact=improvement_type).first()
        if not improvement:
            raise serializers.ValidationError(
                {'name': f'Improvement with name {name} and type {improvement_type} does not exist.'}
            )

        improvement_user = ImprovementUser.objects.filter(improvement=improvement, user=user)
        if improvement_user.exists():
            raise serializers.ValidationError({'improvement': f'Improvement {name} already exist.'})

        if improvement.cost > user.user_profile.credits:
            raise serializers.ValidationError({'cost': 'Not enough credits.'})

        self.context['improvement'] = improvement
        return attrs

    def create(self, validated_data):
        improvement = self.context.get('improvement')
        user = self.context.get('user')
        user.user_profile.credits -= improvement.cost
        user.user_profile.save()
        improvement_user = ImprovementUser.objects.create(user=user, improvement=improvement)
        return improvement_user


class EquipImprovementSerializer(serializers.Serializer):
    name = serializers.CharField()
    improvement_type = serializers.CharField()

    def validate(self, attrs):
        name = attrs.get('name')
        improvement_type = attrs.get('improvement_type')
        user = self.context.get('user')

        improvement = Improvement.objects.filter(name__iexact=name, improvement_type__iexact=improvement_type).first()
        if not improvement:
            raise serializers.ValidationError(
                {'name': f'Improvement with name {name} and type {improvement_type} does not exist.'}
            )

        improvement_user = ImprovementUser.objects.filter(improvement=improvement, user=user).first()
        if not improvement_user:
            raise serializers.ValidationError(
                {
                    'improvement': f'Improvement with name {name} and type {improvement_type} does not exist for this user.'
                }
            )

        self.context['improvement'] = improvement
        self.context['improvement_user'] = improvement_user
        return attrs

    def create(self, validated_data):
        improvement = self.context.get('improvement')
        improvement_user = self.context.get('improvement_user')
        user = self.context.get('user')

        ImprovementUser.objects.filter(
            user=user, improvement__improvement_type=improvement_user.improvement.improvement_type
        ).exclude(pk=improvement_user.pk).update(equipped=False)

        ImprovementUser.objects.filter(user=user, improvement=improvement_user.improvement).update(equipped=True)
        if improvement.improvement_type == 'WINGS' and improvement.bonus_core_cap > 0:
            user.user_profile.core_cap += improvement.bonus_core_cap
            user.user_profile.save()

        return improvement_user.improvement
