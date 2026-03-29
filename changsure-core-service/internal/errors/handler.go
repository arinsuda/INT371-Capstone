package errors

import (
	"errors"
	"log/slog"

	"changsure-core-service/internal/validation"

	"github.com/gofiber/fiber/v3"
)

type ErrorResponse struct {
	Status  string                  `json:"status"`
	Message string                  `json:"message"`
	Errors  []validation.FieldError `json:"errors,omitempty"`
}

func respond(c fiber.Ctx, code int, msg string, fields []validation.FieldError) error {
	resp := ErrorResponse{Status: "error", Message: msg}
	if len(fields) > 0 {
		resp.Errors = fields
	}
	return c.Status(code).JSON(resp)
}

func BadRequest(c fiber.Ctx, msg string, details ...[]validation.FieldError) error {
	var fields []validation.FieldError
	if len(details) > 0 {
		fields = details[0]
	}
	return respond(c, fiber.StatusBadRequest, msg, fields)
}

func NotFound(c fiber.Ctx, msg string) error {
	return respond(c, fiber.StatusNotFound, msg, nil)
}

func InternalError(c fiber.Ctx, msg string, cause error) error {
	if cause != nil {
		slog.Error("internal error", "message", msg, "error", cause)
	}
	return respond(c, fiber.StatusInternalServerError, msg, nil)
}

func Unauthorized(c fiber.Ctx, msg string) error {
	return respond(c, fiber.StatusUnauthorized, msg, nil)
}

func Forbidden(c fiber.Ctx, msg string) error {
	return respond(c, fiber.StatusForbidden, msg, nil)
}

func Conflict(c fiber.Ctx, msg string) error {
	return respond(c, fiber.StatusConflict, msg, nil)
}

func ValidationError(c fiber.Ctx, details []validation.FieldError) error {
	return BadRequest(c, "Validation failed", details)
}

func UnprocessableEntity(c fiber.Ctx, msg string) error {
	return respond(c, fiber.StatusUnprocessableEntity, msg, nil)
}

func InternalServerError(c fiber.Ctx, msg string) error {
	return respond(c, fiber.StatusInternalServerError, msg, nil)
}

func ServiceUnavailable(c fiber.Ctx, msg string) error {
	return respond(c, fiber.StatusServiceUnavailable, msg, nil)
}

func NotImplemented(c fiber.Ctx, msg string) error {
	return respond(c, fiber.StatusNotImplemented, msg, nil)
}

func TooManyRequests(c fiber.Ctx, msg string) error {
	return respond(c, fiber.StatusTooManyRequests, msg, nil)
}

func HandleError(c fiber.Ctx, err error) error {
	var appErr *AppError
	if !errors.As(err, &appErr) {

		return InternalError(c, "An unexpected error occurred", err)
	}

	switch appErr.Code {
	case fiber.StatusNotFound:
		return NotFound(c, appErr.Message)
	case fiber.StatusForbidden:
		return Forbidden(c, appErr.Message)
	case fiber.StatusBadRequest:
		return BadRequest(c, appErr.Message)
	case fiber.StatusUnauthorized:
		return Unauthorized(c, appErr.Message)
	case fiber.StatusConflict:
		return Conflict(c, appErr.Message)
	case fiber.StatusUnprocessableEntity:
		return UnprocessableEntity(c, appErr.Message)
	case fiber.StatusServiceUnavailable:
		return ServiceUnavailable(c, appErr.Message)
	case fiber.StatusNotImplemented:
		return NotImplemented(c, appErr.Message)
	case fiber.StatusTooManyRequests:
		return TooManyRequests(c, appErr.Message)
	case fiber.StatusInternalServerError:
		return InternalError(c, appErr.Message, appErr.Unwrap())
	default:
		return InternalError(c, appErr.Message, appErr.Unwrap())
	}
}
