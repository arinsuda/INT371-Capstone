package routes

import (
	"fmt"
	"strings"

	"github.com/gofiber/fiber/v3"
	"gorm.io/gorm"

	"changsure-core-service/internal/config"
	"changsure-core-service/internal/middleware"
	ocrroutes "changsure-core-service/internal/modules/ocr/routes"
	"changsure-core-service/internal/registry"
)

func Setup(app *fiber.App, cfg *config.Config, db *gorm.DB) {
	middleware.SetupMiddleware(app, cfg)

	container, err := registry.NewContainer(db, cfg)
	if err != nil {
		panic(fmt.Errorf("failed to create container: %w", err))
	}

	setupPublicRoutes(app, db, cfg)
	setupAPIv1Routes(app, cfg, container)
	setup404Handler(app)
	logRegisteredRoutes(app)
}

func setupPublicRoutes(app *fiber.App, db *gorm.DB, cfg *config.Config) {
	setupHealthRoutes(app, db)

	if cfg.App.Environment == "development" {
		setupTestTools(app, cfg)
	}
}

func setupAPIv1Routes(app *fiber.App, cfg *config.Config, container *registry.Container) {
	api := app.Group("/api/v1")

	setupPublicAPIRoutes(api, container)
	setupAuthenticatedRoutes(api, cfg, container)
}

func setupPublicAPIRoutes(api fiber.Router, container *registry.Container) {
	container.AuthHandler.RegisterRoutes(api)
}

func setupAuthenticatedRoutes(api fiber.Router, cfg *config.Config, container *registry.Container) {
	authenticated := api.Group("", middleware.AuthMiddleware(cfg))

	setupCommonRoutes(authenticated, container)
	setupAdminRoutes(authenticated, container)
	setupCustomerRoutes(authenticated, container)
	setupTechnicianRoutes(authenticated, container)
}

func setupCommonRoutes(auth fiber.Router, container *registry.Container) {
	common := auth.Group("")

	container.ProvinceHandler.RegisterRoutes(common)
	container.ServiceCategoryHandler.RegisterRoutes(common)
	container.ServiceHandler.RegisterRoutes(common)
	ocrroutes.Register(common, container.OCRHandler)
}

func setupAdminRoutes(auth fiber.Router, container *registry.Container) {
	admin := auth.Group("", middleware.AdminOnly())

	container.BadgeHandler.RegisterRoutes(admin)
}

func setupCustomerRoutes(auth fiber.Router, container *registry.Container) {
	customer := auth.Group("", middleware.CustomerOnly())

	container.CustomerHandler.RegisterRoutes(customer)
	container.CustomerAddressHandler.RegisterRoutes(customer)
}

func setupTechnicianRoutes(auth fiber.Router, container *registry.Container) {
	technician := auth.Group("", middleware.TechnicianOnly())

	container.TechnicianHandler.RegisterRoutes(technician)
	container.TechnicianServiceHandler.RegisterRoutes(technician)
	container.TechnicianWorkHandler.RegisterRoutes(technician)
}

func setupHealthRoutes(app *fiber.App, db *gorm.DB) {
	health := app.Group("/")

	health.Get("/", handleRootEndpoint)
	health.Get("/health", handleHealthCheck)
	health.Get("/health/detailed", handleDetailedHealthCheck(db))
	health.Get("/ready", handleReadinessCheck(db))
	health.Get("/alive", handleLivenessCheck)
}

func handleRootEndpoint(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"success": true,
		"message": "Welcome to Changsure Core Service API",
		"version": "1.0.0",
	})
}

func handleHealthCheck(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"success": true,
		"message": "Server is running",
	})
}

func handleDetailedHealthCheck(db *gorm.DB) fiber.Handler {
	return func(c fiber.Ctx) error {
		dbStatus := checkDatabaseHealth(db)

		return c.JSON(fiber.Map{
			"success": true,
			"services": fiber.Map{
				"database": dbStatus,
			},
		})
	}
}

func handleReadinessCheck(db *gorm.DB) fiber.Handler {
	return func(c fiber.Ctx) error {
		if checkDatabaseHealth(db) != "healthy" {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"success": false,
				"message": "Service not ready",
				"reason":  "database unavailable",
			})
		}

		return c.JSON(fiber.Map{
			"success": true,
			"message": "Service ready",
		})
	}
}

func handleLivenessCheck(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"success": true,
		"message": "Service alive",
	})
}

func checkDatabaseHealth(db *gorm.DB) string {
	sqlDB, err := db.DB()
	if err != nil {
		return "unhealthy"
	}

	if err := sqlDB.Ping(); err != nil {
		return "unhealthy"
	}

	return "healthy"
}

func setupTestTools(app *fiber.App, cfg *config.Config) {
	app.Get("/ocr/test", handleOCRTestPage)
}

func handleOCRTestPage(c fiber.Ctx) error {
	c.Set("Content-Security-Policy", buildCSP())
	return c.SendFile("./test.html")
}

func buildCSP() string {
	policies := []string{
		"default-src 'self'",
		"img-src 'self' data: blob:",
		"connect-src 'self' http://localhost:8080 http://127.0.0.1:8080 ws: wss:",
		"script-src 'self' 'unsafe-inline'",
		"style-src 'self' 'unsafe-inline'",
		"font-src 'self' data:",
		"worker-src 'self' blob:",
		"object-src 'none'",
		"base-uri 'self'",
		"frame-ancestors 'none'",
		"form-action 'self'",
	}
	return strings.Join(policies, "; ")
}

func setup404Handler(app *fiber.App) {
	app.Use(handle404)
}

func handle404(c fiber.Ctx) error {
	return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
		"success": false,
		"message": "Route not found",
		"data": fiber.Map{
			"path":   c.Path(),
			"method": c.Method(),
		},
	})
}

func logRegisteredRoutes(app *fiber.App) {
	fmt.Println("\n=== Registered Routes ===")
	for _, route := range app.GetRoutes() {
		fmt.Printf("%-6s %s\n", route.Method, route.Path)
	}
	fmt.Println("========================\n")
}
