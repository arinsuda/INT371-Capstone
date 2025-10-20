// middleware/security.go
package middleware

import "github.com/gofiber/fiber/v3"

func CSP() fiber.Handler {
    // Dev policy: อนุญาต data: สำหรับรูป และ fetch ไป :8080
    const policy = "default-src 'self'; " +
        "img-src 'self' data: blob:; " +
        "connect-src 'self' http://localhost:8080 http://127.0.0.1:8080; " +
        "style-src 'self' 'unsafe-inline'; " +
        "script-src 'self' 'unsafe-inline'; " +
        "base-uri 'self'; frame-ancestors 'self'"

    return func(c fiber.Ctx) error {
        c.Set("Content-Security-Policy", policy)
        return c.Next()
    }
}
