package routes

import (
	"changsure-core-service/configs"
	"changsure-core-service/pkg/middleware"
	"changsure-core-service/pkg/registry"

	"github.com/gofiber/fiber/v3"
	"gorm.io/gorm"
)

// Setup initializes all routes
func Setup(app *fiber.App, config *configs.Config, db *gorm.DB) {
	// Setup middleware
	middleware.SetupMiddleware(app, config)

	// Initialize dependency container
	container := registry.NewContainer(db)

	// Health check routes
	setupHealthRoutes(app, db)

	// API v1 routes
	setupAPIv1Routes(app, container)

	// 404 handler (must be last)
	setup404Handler(app)
}

// setupAPIv1Routes sets up all API v1 routes
func setupAPIv1Routes(app *fiber.App, container *registry.Container) {
	api := app.Group("/api/v1")

	// Register module routes
	container.CustomerHandler.RegisterRoutes(api)
	// container.TechnicianHandler.RegisterRoutes(api)
	// container.ReservationHandler.RegisterRoutes(api)
}

// setupHealthRoutes sets up health check endpoints
func setupHealthRoutes(app *fiber.App, db *gorm.DB) {
	// Simple health check
	app.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"message": "Server is running",
		})
	})

	// Detailed health check
	app.Get("/health/detailed", func(c fiber.Ctx) error {
		dbStatus := "healthy"
		sqlDB, err := db.DB()
		if err != nil || sqlDB.Ping() != nil {
			dbStatus = "unhealthy"
		}

		return c.JSON(fiber.Map{
			"status": "ok",
			"services": fiber.Map{
				"database": dbStatus,
			},
		})
	})

	// Readiness probe
	app.Get("/ready", func(c fiber.Ctx) error {
		sqlDB, err := db.DB()
		if err != nil || sqlDB.Ping() != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status": "not_ready",
			})
		}
		return c.JSON(fiber.Map{"status": "ready"})
	})

	// Liveness probe
	app.Get("/alive", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "alive"})
	})
}

// setup404Handler handles unknown routes
func setup404Handler(app *fiber.App) {
	app.Use(func(c fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"status":  "error",
			"message": "Route not found",
			"data": fiber.Map{
				"path":   c.Path(),
				"method": c.Method(),
			},
		})
	})
}
