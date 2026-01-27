package errors

import (
	"changsure-core-service/internal/validation"
	"errors"
	"log"

	"github.com/gofiber/fiber/v3"
)

type ErrorResponse struct {
	Status  string                  `json:"status"`
	Message string                  `json:"message"`
	Errors  []validation.FieldError `json:"errors,omitempty"`
}

func BadRequest(c fiber.Ctx, msg string, details ...[]validation.FieldError) error {
	resp := ErrorResponse{
		Status:  "error",
		Message: msg,
	}
	if len(details) > 0 && len(details[0]) > 0 {
		resp.Errors = details[0]
	}
	return c.Status(fiber.StatusBadRequest).JSON(resp)
}

func NotFound(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

func InternalError(c fiber.Ctx, msg string, err error) error {
	if err != nil {
		log.Printf("Internal error: %v", err)
	}

	return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

func Unauthorized(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

func Forbidden(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusForbidden).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

func Conflict(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusConflict).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

func ValidationError(c fiber.Ctx, details []validation.FieldError) error {
	return BadRequest(c, "Validation failed", details)
}

func UnprocessableEntity(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusUnprocessableEntity).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

func InternalServerError(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

func ServiceUnavailable(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusServiceUnavailable).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

func NotImplemented(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusNotImplemented).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

func TooManyRequests(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusTooManyRequests).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

func HandleError(c fiber.Ctx, err error) error {
	var appErr *AppError
	if errors.As(err, &appErr) {
		switch appErr.Code {
		case fiber.StatusNotFound:
			return NotFound(c, appErr.Message)
		case fiber.StatusForbidden:
			return Forbidden(c, appErr.Message)
		case fiber.StatusBadRequest:
			return BadRequest(c, appErr.Message)
		case fiber.StatusUnprocessableEntity:
			return UnprocessableEntity(c, appErr.Message)
		case fiber.StatusInternalServerError:
			return InternalError(c, appErr.Message, appErr.Err)
		case fiber.StatusServiceUnavailable:
			return ServiceUnavailable(c, appErr.Message)
		case fiber.StatusNotImplemented:
			return NotImplemented(c, appErr.Message)
		case fiber.StatusTooManyRequests:
			return TooManyRequests(c, appErr.Message)
		default:
			return InternalError(c, appErr.Message, appErr.Err)
		}
	}

	return InternalError(c, "An unexpected error occurred", err)
}
