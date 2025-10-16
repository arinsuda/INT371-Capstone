package middleware

import (
	"context"
	"strings"
	"time"

	"changsure-core-service/configs"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/timeout"
	"github.com/google/uuid"
)

func SetupMiddleware(app *fiber.App, cfg *configs.Config) {
	// Security headers
	app.Use(Helmet())
	app.Use(SecurityExtras())
	app.Use(Recover())

	// Request tracking
	app.Use(RequestID())
	app.Use(ContextMiddleware()) // ← เพิ่ม Context Middleware

	// CORS
	if cfg.App.Environment == "production" {
		app.Use(CORSProduction([]string{
			"https://yourdomain.com",
			"https://www.yourdomain.com",
		}))
	} else {
		app.Use(CORS())
	}

	// Logging
	if cfg.App.Environment == "production" {
		app.Use(LoggerProduction())
	} else {
		app.Use(Logger())
	}

	// Performance
	app.Use(Compress())

	// Rate limiting
	if cfg.App.Environment == "production" {
		app.Use(StrictRateLimit())
	} else {
		app.Use(RateLimit())
	}
}

// ContextMiddleware injects context.Context into fiber.Ctx
// Compatible with Fiber v3 beta.5
func ContextMiddleware() fiber.Handler {
	return func(c fiber.Ctx) error {
		// Create background context
		ctx := context.Background()

		// Add request ID to context if available
		if reqID, ok := c.Locals("request_id").(string); ok {
			ctx = context.WithValue(ctx, "request_id", reqID)
		}

		// Store context in Locals for retrieval in handlers
		c.Locals("requestContext", ctx)

		return c.Next()
	}
}

// GetContext retrieves context.Context from fiber.Ctx
// Use this in your handlers to get the request context
func GetContext(c fiber.Ctx) context.Context {
	if ctx, ok := c.Locals("requestContext").(context.Context); ok {
		return ctx
	}
	// Fallback to background context
	return context.Background()
}

// APIKeyAuth validates API key from request header
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

// RequestID generates or extracts request ID
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

// Timeout adds timeout to requests
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

// ContentTypeJSON validates JSON content type
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

// MaintenanceMode enables maintenance mode
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
