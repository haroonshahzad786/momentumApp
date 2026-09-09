from .strings import user_has_not_bonus, bonus_already_used


class UserHasNotBonusError(Exception):
    def __init__(self):
        super().__init__(user_has_not_bonus)


class BonusAlreadyUsed(Exception):
    def __init__(self):
        super().__init__(bonus_already_used)
