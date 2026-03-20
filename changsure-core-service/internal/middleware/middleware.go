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

type contextKey string

const (
	localRequestID      = "request_id"
	localRequestContext = "requestContext"
	localAPIKey         = "api_key"
	requestIDHeader     = "X-Request-ID"
)

func SetupMiddleware(app *fiber.App, cfg *config.Config) {
	app.Use(Helmet())
	app.Use(SecurityExtras())
	app.Use(Recover())
	app.Use(RequestID())
	app.Use(ContextMiddleware())

	if cfg.IsProduction() {
		app.Use(CORSProduction(cfg.App.AllowedOrigins))
	} else {
		app.Use(CORS())
	}

	if cfg.IsProduction() {
		app.Use(LoggerProduction())
	} else {
		app.Use(Logger())
	}

	app.Use(Compress())

	if cfg.IsProduction() {
		app.Use(StrictRateLimit())
	} else {
		app.Use(RateLimit())
	}
}

func ContextMiddleware() fiber.Handler {
	return func(c fiber.Ctx) error {
		ctx := context.Background()
		if reqID, ok := c.Locals(localRequestID).(string); ok && reqID != "" {
			ctx = context.WithValue(ctx, contextKey(localRequestID), reqID)
		}
		c.Locals(localRequestContext, ctx)
		return c.Next()
	}
}

func GetContext(c fiber.Ctx) context.Context {
	if ctx, ok := c.Locals(localRequestContext).(context.Context); ok {
		return ctx
	}
	return context.Background()
}

func RequestID() fiber.Handler {
	return func(c fiber.Ctx) error {
		id := c.Get(requestIDHeader)
		if id == "" {
			id = uuid.NewString()
		}
		c.Locals(localRequestID, id)
		c.Set(requestIDHeader, id)
		return c.Next()
	}
}

func APIKeyAuth(validAPIKeys []string) fiber.Handler {
	keySet := make(map[string]struct{}, len(validAPIKeys))
	for _, k := range validAPIKeys {
		keySet[k] = struct{}{}
	}
	return func(c fiber.Ctx) error {
		key := c.Get("X-API-Key")
		if key != "" {
			if _, ok := keySet[key]; ok {
				c.Locals(localAPIKey, key)
				return c.Next()
			}
		}
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"message": "Invalid or missing API Key",
		})
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
					"message": "Request timed out",
				})
			},
		},
	)
}

func ContentTypeJSON() fiber.Handler {
	return func(c fiber.Ctx) error {
		switch c.Method() {
		case fiber.MethodPost, fiber.MethodPut, fiber.MethodPatch:
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
