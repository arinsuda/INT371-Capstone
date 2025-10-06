package routes

import (
	"changsure-core-service/configs"
	"changsure-core-service/pkg/middleware"

	"github.com/gofiber/fiber/v3"
	"gorm.io/gorm"
	"time"
)


func Setup(app *fiber.App, config *configs.Config, db *gorm.DB) {
	
	middleware.SetupMiddleware(app, config)

	
	setupHealthRoutes(app)

	
	setup404Handler(app)
}


func setupHealthRoutes(app *fiber.App) {
	
	app.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":    "ok",
			"message":   "Server is running",
			"timestamp": time.Now().UTC(),
			"version":   "1.0.0",
		})
	})

	
	app.Get("/health/detailed", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":    "ok",
			"timestamp": time.Now().UTC(),
			"version":   "1.0.0",
			"services": fiber.Map{
				"database": checkDatabaseHealth(),
				"redis":    checkRedisHealth(),
			},
			"system": fiber.Map{
				"memory": getMemoryUsage(),
				"uptime": getUptime(),
			},
		})
	})

	
	app.Get("/ready", func(c fiber.Ctx) error {
		if isApplicationReady() {
			return c.JSON(fiber.Map{"status": "ready"})
		}
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"status": "not_ready",
		})
	})

	
	app.Get("/alive", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":    "alive",
			"timestamp": time.Now().UTC(),
		})
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



func checkDatabaseHealth() string {
	
	return "healthy"
}

func checkRedisHealth() string {
	
	return "healthy"
}

func getMemoryUsage() string {
	
	return "256MB / 1GB"
}

func getUptime() string {
	
	return "0d 0h 10m"
}

func isApplicationReady() bool {
	
	return true
}
