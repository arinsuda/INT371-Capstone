class OCRBaseException(Exception):
    pass


class FileTooLargeError(OCRBaseException):
    pass


class InvalidFileTypeError(OCRBaseException):
    pass


class OCREngineNotReadyError(OCRBaseException):
    pass


class OCRTimeoutError(OCRBaseException):
    pass


class RateLimitExceeded(OCRBaseException):
    def __init__(self, limit: int, window: int, retry_after: float):
        self.limit = limit
        self.window = window
        self.retry_after = retry_after
        super().__init__(f"Rate limit: {limit} req/{window}s exceeded")


class BatchTooLargeError(OCRBaseException):
    pass
