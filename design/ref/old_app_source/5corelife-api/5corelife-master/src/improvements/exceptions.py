from .strings import user_already_has_improvement


class UserAlreadyHasImprovementError(Exception):
    def __init__(self):
        super().__init__(user_already_has_improvement)
