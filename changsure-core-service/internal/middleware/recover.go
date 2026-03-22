package middleware

import (
	"log/slog"
	"runtime/debug"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/recover"
)

func Recover() fiber.Handler {
	return recover.New(recover.Config{
		EnableStackTrace: true,
		StackTraceHandler: func(c fiber.Ctx, e interface{}) {
			slog.Error("panic recovered",
				"error", e,
				"path", c.Path(),
				"method", c.Method(),
				"request_id", c.Locals(localRequestID),
				"stack", string(debug.Stack()),
			)
		},
	})
}
