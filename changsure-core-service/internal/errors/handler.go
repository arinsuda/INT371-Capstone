package errors

import (
	"changsure-core-service/internal/validation"
	"log"

	"github.com/gofiber/fiber/v3"
)

type ErrorResponse struct {
	Status  string                  `json:"status"`
	Message string                  `json:"message"`
	Errors  []validation.FieldError `json:"errors,omitempty"`
}

// BadRequest จัดการ error สำหรับ request ที่ไม่ถูกต้อง (400)
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

// NotFound จัดการ error สำหรับข้อมูลที่ไม่พบ (404)
func NotFound(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusNotFound).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

// InternalError จัดการ error ภายในระบบ (500)
func InternalError(c fiber.Ctx, msg string, err error) error {
	if err != nil {
		log.Printf("Internal error: %v", err)
	}

	return c.Status(fiber.StatusInternalServerError).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

// Unauthorized จัดการ error สำหรับการเข้าถึงที่ไม่ได้รับอนุญาต (401)
func Unauthorized(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusUnauthorized).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

// Forbidden จัดการ error สำหรับการเข้าถึงที่ถูกห้าม (403)
func Forbidden(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusForbidden).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

// Conflict จัดการ error สำหรับข้อมูลที่ซ้ำกัน (409)
func Conflict(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusConflict).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}

// ValidationError จัดการ error จาก validation (400)
func ValidationError(c fiber.Ctx, details []validation.FieldError) error {
	return BadRequest(c, "Validation failed", details)
}

// UnprocessableEntity จัดการ error สำหรับข้อมูลที่ถูกต้องแต่ประมวลผลไม่ได้ (422)
func UnprocessableEntity(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusUnprocessableEntity).JSON(ErrorResponse{
		Status:  "error",
		Message: msg,
	})
}
