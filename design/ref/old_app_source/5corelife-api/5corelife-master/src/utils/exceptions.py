from .strings import insufficient_credits


class InsufficientCreditsError(Exception):
    """Exception raised for errors when purchasing elements."""

    def __init__(self):
        super().__init__(insufficient_credits)
