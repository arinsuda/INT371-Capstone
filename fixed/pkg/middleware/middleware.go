package middleware

import (
	"fixed/configs"
	"fixed/utils"
	"strings"
	"time"

	"github.com/gofiber/fiber/v3"
)

// SetupMiddleware applies all global middlewares
func SetupMiddleware(app *fiber.App, config *configs.Config) {
	// Security middleware
	app.Use(Helmet())
	app.Use(Recover())

	// CORS
	if config.App.Environment == "production" {
		app.Use(CORSProduction([]string{
			"https://yourdomain.com",
			"https://www.yourdomain.com",
		}))
	} else {
		app.Use(CORS())
	}

	// Logging
	if config.App.Environment == "production" {
		app.Use(LoggerProduction())
	} else {
		app.Use(Logger())
	}

	// Compression
	app.Use(Compress())

	// Rate limiting
	if config.App.Environment == "production" {
		app.Use(StrictRateLimit())
	} else {
		app.Use(RateLimit())
	}
}

// Additional Utility Middlewares
func APIKeyAuth(validAPIKeys []string) fiber.Handler {
	return func(c fiber.Ctx) error {
		apiKey := c.Get("X-API-Key")
		if apiKey == "" {
			return utils.ErrorResponse(c, fiber.StatusUnauthorized, "API Key required", nil)
		}

		// Check if API key is valid
		for _, validKey := range validAPIKeys {
			if apiKey == validKey {
				c.Locals("api_key", apiKey)
				return c.Next()
			}
		}

		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "Invalid API Key", nil)
	}
}

func RequestID() fiber.Handler {
	return func(c fiber.Ctx) error {
		// Generate or get request ID
		requestID := c.Get("X-Request-ID")
		if requestID == "" {
			// Generate new UUID for request ID
			requestID = utils.GenerateUUID() // สมมติว่ามี function นี้ใน utils
		}

		c.Locals("request_id", requestID)
		c.Set("X-Request-ID", requestID)

		return c.Next()
	}
}

func Timeout(duration time.Duration) fiber.Handler {
	return func(c fiber.Ctx) error {
		// Set timeout for request
		c.SetUserContext(utils.WithTimeout(c.UserContext(), duration))
		return c.Next()
	}
}

func ContentTypeJSON() fiber.Handler {
	return func(c fiber.Ctx) error {
		// Ensure request content type is JSON for POST/PUT/PATCH
		if c.Method() == "POST" || c.Method() == "PUT" || c.Method() == "PATCH" {
			contentType := c.Get("Content-Type")
			if !strings.Contains(contentType, "application/json") {
				return utils.ErrorResponse(c, fiber.StatusUnsupportedMediaType, "Content-Type must be application/json", nil)
			}
		}
		return c.Next()
	}
}

func MaintenanceMode(enabled bool, message string) fiber.Handler {
	return func(c fiber.Ctx) error {
		if enabled {
			// Skip maintenance for health checks and admin routes
			if strings.HasPrefix(c.Path(), "/health") ||
				strings.HasPrefix(c.Path(), "/api/v1/admin") {
				return c.Next()
			}

			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "maintenance",
				"message": message,
			})
		}
		return c.Next()
	}
}
