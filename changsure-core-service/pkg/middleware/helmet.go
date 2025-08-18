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
		HSTSMaxAge:         31536000, // 1 year
		// หมายเหตุ: 'unsafe-inline' ใช้ง่ายตอน dev; ถ้า prod แนะนำใช้ nonce/hash
		ContentSecurityPolicy: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';",
		ReferrerPolicy:        "strict-origin-when-cross-origin",
		// (ตัด HSTSIncludeSubdomains, PermissionsPolicy ออก)
	})
}

func SecurityExtras() fiber.Handler {
	return func(c fiber.Ctx) error {
		// เพิ่ม option includeSubDomains ให้กับ Strict-Transport-Security
		c.Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")

		// ปิดการใช้ hardware features ของ browser
		c.Set("Permissions-Policy", "camera=(), microphone=(), geolocation=()")

		return c.Next()
	}
}

