package errors

import "fmt"

type OCRError struct {
	Code    string
	Message string
	Err     error
}

func NewOCRError(code, message string, err error) *OCRError {
	return &OCRError{
		Code:    code,
		Message: message,
		Err:     err,
	}
}

func (e *OCRError) Error() string {
	if e.Err != nil {
		return e.Message + ": " + e.Err.Error()
	}
	return e.Message
}

type FileTooLargeError struct{ Max int64 }

func NewFileTooLargeError(max int64) error { return &FileTooLargeError{Max: max} }
func (e *FileTooLargeError) Error() string {
	return fmt.Sprintf("file too large (max %d bytes)", e.Max)
}

type UnsupportedFormatError struct{ CT string }

func NewUnsupportedFormatError(ct string) error { return &UnsupportedFormatError{CT: ct} }
func (e *UnsupportedFormatError) Error() string {
	return fmt.Sprintf("unsupported content type: %s", e.CT)
}

type InvalidFileError struct {
	Msg string
	Err error
}

func NewInvalidFileError(msg string, err error) error { return &InvalidFileError{Msg: msg, Err: err} }
func (e *InvalidFileError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %v", e.Msg, e.Err)
	}
	return e.Msg
}
