package middleware

import (
	"log"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/recover"
)

func Recover() fiber.Handler {
	return recover.New(recover.Config{
		EnableStackTrace: true,
		StackTraceHandler: func(c fiber.Ctx, e interface{}) {
			// ใช้สำหรับ log เท่านั้น ให้ Fiber ตอบ 500 เอง
			log.Printf("[panic] %v | path=%s", e, c.Path())
		},
	})
}
