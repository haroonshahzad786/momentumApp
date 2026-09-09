from .strings import journey_already_started


class JourneyStarted(Exception):
    def __init__(self):
        super().__init__(journey_already_started)
