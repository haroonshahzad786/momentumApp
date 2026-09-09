from .strings import quest_not_assigned, user_has_quest_assigned


class QuestNotAssigned(Exception):
    def __init__(self):
        super().__init__(quest_not_assigned)


class UserHasQuestAssigned(Exception):
    def __init__(self):
        super().__init__(user_has_quest_assigned)
