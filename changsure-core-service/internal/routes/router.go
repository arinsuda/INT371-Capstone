package routes

import (
	"changsure-core-service/internal/config"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/registry"

	"github.com/gofiber/fiber/v3"
	"gorm.io/gorm"

	"fmt"
)

func Setup(app *fiber.App, config *config.Config, db *gorm.DB) {
	middleware.SetupMiddleware(app, config)

	container, err := registry.NewContainer(db)
	if err != nil {
		panic(err)
	}

	// 🆕 เพิ่มบรรทัดนี้
	setupHealthRoutes(app, db)
	setupTestTools(app, config)
	setupAPIv1Routes(app, container)
	setup404Handler(app)

	for _, r := range app.GetRoutes() {
		fmt.Printf("Route registered: %s %s\n", r.Method, r.Path)
	}
}

func setupAPIv1Routes(app *fiber.App, container *registry.Container) {
	api := app.Group("/api/v1")

	// Register module routes
	container.CustomerHandler.RegisterRoutes(api)
}

func setupTestTools(app *fiber.App, config *config.Config) {
	app.Get("/test", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"message": "Test route is working!",
			"env":     config.App.Environment,
		})
	})
}

func setupHealthRoutes(app *fiber.App, db *gorm.DB) {
	app.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"message": "Server is running",
		})
	})

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

	app.Get("/ready", func(c fiber.Ctx) error {
		sqlDB, err := db.DB()
		if err != nil || sqlDB.Ping() != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status": "not_ready",
			})
		}
		return c.JSON(fiber.Map{"status": "ready"})
	})

	app.Get("/alive", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "alive"})
	})
}

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
