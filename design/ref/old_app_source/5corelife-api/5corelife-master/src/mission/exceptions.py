from .strings import mission_not_assigned, user_has_mission_assigned


class MissionNotAssigned(Exception):
    def __init__(self):
        super().__init__(mission_not_assigned)


class UserHasMissionAssigned(Exception):
    def __init__(self):
        super().__init__(user_has_mission_assigned)
