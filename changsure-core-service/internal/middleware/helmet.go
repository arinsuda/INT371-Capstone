package middleware

import (
	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/helmet"
)

func Helmet() fiber.Handler {
	return helmet.New(helmet.Config{
		XSSProtection:      "1; mode=block",
		ContentTypeNosniff: "nosniff",
		XFrameOptions:      "DENY",
		HSTSMaxAge:         31536000,

		ContentSecurityPolicy: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';",
		ReferrerPolicy:        "strict-origin-when-cross-origin",
	})
}

func SecurityExtras() fiber.Handler {
	return func(c fiber.Ctx) error {

		c.Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")

		c.Set("Permissions-Policy", "camera=(), microphone=(), geolocation=()")

		return c.Next()
	}
}
