class OCRBaseException(Exception):
    status_code: int = 500
    error_code: str = "OCR_ERROR"
    message: str = "OCR processing failed"

    def __init__(self, message: str | None = None):
        self.message = message or self.__class__.message
        super().__init__(self.message)


class FileTooLargeError(OCRBaseException):
    status_code = 413
    error_code = "FILE_TOO_LARGE"
    message = "Uploaded file exceeds maximum allowed size"


class InvalidFileTypeError(OCRBaseException):
    status_code = 415
    error_code = "INVALID_FILE_TYPE"
    message = "File type not supported"


class InvalidImageError(OCRBaseException):
    status_code = 422
    error_code = "INVALID_IMAGE"
    message = "Cannot decode image"


class ImageTooSmallError(OCRBaseException):
    status_code = 422
    error_code = "IMAGE_TOO_SMALL"
    message = "Image resolution is too low for reliable OCR"


class OCRTimeoutError(OCRBaseException):
    status_code = 504
    error_code = "OCR_TIMEOUT"
    message = "OCR processing timed out"


class OCREngineError(OCRBaseException):
    status_code = 500
    error_code = "OCR_ENGINE_ERROR"
    message = "OCR engine encountered an internal error"
