package errors

import "net/http"

type AppError struct {
	Code    int
	Message string
	Err     error
}

func (e *AppError) Error() string {
	return e.Message
}

func NewNotFound(message string) *AppError {
	return &AppError{Code: http.StatusNotFound, Message: message}
}

func NewForbidden(message string) *AppError {
	return &AppError{Code: http.StatusForbidden, Message: message}
}

func NewBadRequest(message string) *AppError {
	return &AppError{Code: http.StatusBadRequest, Message: message}
}

func NewInternal(err error) *AppError {
	return &AppError{
		Code:    http.StatusInternalServerError,
		Message: "Internal Server Error",
		Err:     err,
	}
}

func NewUnprocessable(message string) *AppError {
	return &AppError{Code: http.StatusUnprocessableEntity, Message: message}
}
