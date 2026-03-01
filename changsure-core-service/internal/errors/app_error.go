package errors

import (
	"errors"
	"fmt"
	"net/http"
)

var (
	ErrNotFound        = errors.New("not found")
	ErrForbidden       = errors.New("forbidden")
	ErrBadRequest      = errors.New("bad request")
	ErrUnprocessable   = errors.New("unprocessable entity")
	ErrInternal        = errors.New("internal server error")
	ErrUnauthorized    = errors.New("unauthorized")
	ErrConflict        = errors.New("conflict")
	ErrServiceUnavail  = errors.New("service unavailable")
	ErrNotImplemented  = errors.New("not implemented")
	ErrTooManyRequests = errors.New("too many requests")
)

type AppError struct {
	Code    int
	Message string
	cause   error
}

func (e *AppError) Error() string {
	return e.Message
}

func (e *AppError) Unwrap() error {
	return e.cause
}

func (e *AppError) Is(target error) bool {
	var t *AppError
	if errors.As(target, &t) {
		return e.Code == t.Code
	}
	return false
}

func newAppError(code int, message string, cause error) *AppError {
	return &AppError{Code: code, Message: message, cause: cause}
}

func NewNotFound(message string) *AppError {
	return newAppError(http.StatusNotFound, message, ErrNotFound)
}

func NewForbidden(message string) *AppError {
	return newAppError(http.StatusForbidden, message, ErrForbidden)
}

func NewBadRequest(message string) *AppError {
	return newAppError(http.StatusBadRequest, message, ErrBadRequest)
}

func NewInternal(cause error) *AppError {
	msg := "Internal Server Error"
	if cause != nil {
		msg = fmt.Sprintf("Internal Server Error: %v", cause)
	}
	return newAppError(http.StatusInternalServerError, msg, fmt.Errorf("%w: %w", ErrInternal, cause))
}

func NewUnprocessable(message string) *AppError {
	return newAppError(http.StatusUnprocessableEntity, message, ErrUnprocessable)
}

func NewUnauthorized(message string) *AppError {
	return newAppError(http.StatusUnauthorized, message, ErrUnauthorized)
}

func NewConflict(message string) *AppError {
	return newAppError(http.StatusConflict, message, ErrConflict)
}

func NewServiceUnavailable(message string) *AppError {
	return newAppError(http.StatusServiceUnavailable, message, ErrServiceUnavail)
}

func NewNotImplemented(message string) *AppError {
	return newAppError(http.StatusNotImplemented, message, ErrNotImplemented)
}

func NewTooManyRequests(message string) *AppError {
	return newAppError(http.StatusTooManyRequests, message, ErrTooManyRequests)
}
