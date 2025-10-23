package middleware

import (
	"context"
	"strings"
	"time"

	"changsure-core-service/internal/config"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/timeout"
	"github.com/google/uuid"
)

func SetupMiddleware(app *fiber.App, cfg *config.Config) {

	app.Use(Helmet())
	app.Use(SecurityExtras())
	app.Use(Recover())

	app.Use(RequestID())
	app.Use(ContextMiddleware())

	if cfg.App.Environment == "production" {
		app.Use(CORSProduction([]string{
			"https://yourdomain.com",
			"https://www.yourdomain.com",
		}))
	} else {
		app.Use(CORS())
	}

	if cfg.App.Environment == "production" {
		app.Use(LoggerProduction())
	} else {
		app.Use(Logger())
	}

	app.Use(Compress())

	if cfg.App.Environment == "production" {
		app.Use(StrictRateLimit())
	} else {
		app.Use(RateLimit())
	}
}

func ContextMiddleware() fiber.Handler {
	return func(c fiber.Ctx) error {

		ctx := context.Background()

		if reqID, ok := c.Locals("request_id").(string); ok {
			ctx = context.WithValue(ctx, "request_id", reqID)
		}

		c.Locals("requestContext", ctx)

		return c.Next()
	}
}

func GetContext(c fiber.Ctx) context.Context {
	if ctx, ok := c.Locals("requestContext").(context.Context); ok {
		return ctx
	}

	return context.Background()
}

func APIKeyAuth(validAPIKeys []string) fiber.Handler {
	return func(c fiber.Ctx) error {
		if key := c.Get("X-API-Key"); key != "" {
			for _, k := range validAPIKeys {
				if key == k {
					c.Locals("api_key", key)
					return c.Next()
				}
			}
		}
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"message": "Invalid or missing API Key",
		})
	}
}

func RequestID() fiber.Handler {
	return func(c fiber.Ctx) error {
		id := c.Get("X-Request-ID")
		if id == "" {
			id = uuid.NewString()
		}
		c.Locals("request_id", id)
		c.Set("X-Request-ID", id)
		return c.Next()
	}
}

func Timeout(d time.Duration) fiber.Handler {
	return timeout.New(
		func(c fiber.Ctx) error { return c.Next() },
		timeout.Config{
			Timeout: d,
			OnTimeout: func(c fiber.Ctx) error {
				return c.Status(fiber.StatusGatewayTimeout).JSON(fiber.Map{
					"success": false,
					"message": "request timed out",
				})
			},
		},
	)
}

func ContentTypeJSON() fiber.Handler {
	return func(c fiber.Ctx) error {
		if m := c.Method(); m == fiber.MethodPost || m == fiber.MethodPut || m == fiber.MethodPatch {
			ct := strings.ToLower(c.Get("Content-Type"))
			if ct == "" || !strings.HasPrefix(ct, "application/json") {
				return c.Status(fiber.StatusUnsupportedMediaType).JSON(fiber.Map{
					"success": false,
					"message": "Content-Type must be application/json",
				})
			}
		}
		return c.Next()
	}
}

func MaintenanceMode(enabled bool, msg string) fiber.Handler {
	return func(c fiber.Ctx) error {
		if !enabled {
			return c.Next()
		}
		p := c.Path()
		if p == "/health" || strings.HasPrefix(p, "/api/v1/admin") {
			return c.Next()
		}
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"status":  "maintenance",
			"message": msg,
		})
	}
}
