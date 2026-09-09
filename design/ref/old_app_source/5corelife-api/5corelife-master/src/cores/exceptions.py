from .strings import core_already_enabled


class CoreAlreadyEnabled(Exception):
    def __init__(self):
        super().__init__(core_already_enabled)
