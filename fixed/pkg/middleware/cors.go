package middleware

import (
	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"

	"strings"
)

func CORS() fiber.Handler {
	return cors.New(cors.Config{
		AllowOrigins:     "*",
		AllowMethods:     "GET,POST,HEAD,PUT,DELETE,PATCH,OPTIONS",
		AllowHeaders:     "Origin,Content-Type,Accept,Authorization,X-Requested-With,X-API-Key",
		AllowCredentials: false,
		MaxAge:           86400, // 24 hours
	})
}

func CORSProduction(allowedOrigins []string) fiber.Handler {
	return cors.New(cors.Config{
		AllowOrigins:     strings.Join(allowedOrigins, ","),
		AllowMethods:     "GET,POST,HEAD,PUT,DELETE,PATCH",
		AllowHeaders:     "Origin,Content-Type,Accept,Authorization,X-Requested-With,X-API-Key",
		AllowCredentials: true,
		MaxAge:           86400,
		Next: func(c fiber.Ctx) bool {
			// Skip CORS for health checks
			return strings.HasPrefix(c.Path(), "/health")
		},
	})
}
