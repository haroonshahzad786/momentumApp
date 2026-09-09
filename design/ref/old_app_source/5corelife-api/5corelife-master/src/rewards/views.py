from random import randint, shuffle

from bonus.models import Bonus, BonusUser
from improvements.models import Improvement, ImprovementUser


def obtain_reward(user):
    """
    Assign a randomized reward to user (Bonus or Improvement)

    Parameters:
    user (User): An user

    Returns:
    string: name of reward
    """
    probability_result = randint(1, 100)
    filter_probability = 0
    # 5%
    if probability_result <= 5:
        filter_probability = 5
    # 10%
    elif 5 < probability_result <= 15:
        filter_probability = 10
    # 15%
    elif 15 < probability_result <= 30:
        filter_probability = 15
    # 20%
    elif 30 < probability_result <= 50:
        filter_probability = 20
    else:
        return None
    # From whole list:
    #   1º: filter those which have the correspondent probability
    #   2º: intersect with the list obtained from user belongings
    bonus_possibles = Bonus.objects.filter(probability_reward=filter_probability).difference(
        Bonus.objects.filter(pk__in=BonusUser.objects.filter(user=user, used=True).values_list("bonus", flat=True)))
    improvements_possibles = Improvement.objects.filter(probability_reward=filter_probability).difference(
        Improvement.objects.filter(pk__in=ImprovementUser.objects.filter(user=user).values_list("improvement",
                                                                                                flat=True)))
    bonus_improvements_possibles = list(bonus_possibles) + list(improvements_possibles)
    shuffle([i for i in improvements_possibles])
    if len(improvements_possibles) == 0:
        return None

    reward = bonus_improvements_possibles[randint(0, len(improvements_possibles)-1)]
    if isinstance(reward, Bonus):
        bonus_user = BonusUser(user=user, bonus=reward)
        bonus_user.save()
    elif isinstance(reward, Improvement):
        improvement_user = ImprovementUser(user=user, improvement=reward)
        improvement_user.save()
    return reward.name
