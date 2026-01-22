package routes

import (
	"fmt"
	"log"
	"strings"

	"github.com/gofiber/fiber/v3"
	"gorm.io/gorm"

	"changsure-core-service/internal/config"
	"changsure-core-service/internal/middleware"
	ocrroutes "changsure-core-service/internal/modules/ocr/routes"
	"changsure-core-service/internal/registry"

	realtime "changsure-core-service/internal/realtime"
	"github.com/gofiber/contrib/v3/websocket"
)

// Router manages application route setup
type Router struct {
	app       *fiber.App
	cfg       *config.Config
	db        *gorm.DB
	container *registry.Container

	hub *realtime.Hub
}

// NewRouter creates a new router instance
func NewRouter(app *fiber.App, cfg *config.Config, db *gorm.DB) (*Router, error) {
	hub := realtime.NewHub()

	container, err := registry.NewContainer(db, cfg, hub)
	if err != nil {
		return nil, fmt.Errorf("failed to create container: %w", err)
	}

	return &Router{
		app:       app,
		cfg:       cfg,
		db:        db,
		container: container,
		hub:       hub,
	}, nil
}

// Setup configures all application routes
func (r *Router) Setup() {
	// Setup middleware
	middleware.SetupMiddleware(r.app, r.cfg)

	// Setup routes in order
	r.setupHealthRoutes()
	r.setupWebSocketRoutes()
	r.setupPublicRoutes()
	r.setupProtectedRoutes()
	r.setup404Handler()

	// Log routes in development
	if r.cfg.App.Environment == "development" {
		r.logRegisteredRoutes()
	}
}

// setupHealthRoutes configures health check endpoints
func (r *Router) setupHealthRoutes() {
	r.app.Get("/", r.handleRoot)
	r.app.Get("/health", r.handleHealth)
	r.app.Get("/health/detailed", r.handleDetailedHealth)
	r.app.Get("/ready", r.handleReadiness)
	r.app.Get("/alive", r.handleLiveness)
}

// setupPublicRoutes configures public API endpoints
func (r *Router) setupPublicRoutes() {
	v1 := r.app.Group("/api/v1")

	// Authentication routes (no auth required)
	auth := v1.Group("/auth")
	r.container.AuthHandler.RegisterRoutes(auth)

	// Development tools
	if r.cfg.App.Environment == "development" {
		r.setupDevelopmentTools()
	}
}

// setupProtectedRoutes configures authenticated API endpoints
func (r *Router) setupProtectedRoutes() {
	v1 := r.app.Group("/api/v1", middleware.AuthMiddleware(r.cfg))

	// Shared resources
	r.setupSharedResources(v1)

	r.setupCustomerMeRoutes(v1)
	r.setupTechnicianMeRoutes(v1)
	
	// Domain-specific resources
	r.setupTechnicianPublicRoutes(v1)
	// r.setupCustomerRoutes(v1)

}

func (r *Router) setupWebSocketRoutes() {
	verifyFn := func(token string) (uint, string, bool) {
		token = strings.TrimSpace(strings.TrimPrefix(token, "Bearer "))
		if token == "" {
			return 0, "", false
		}

		claims, err := middleware.ParseToken(token, r.cfg.JWT.Secret)
		if err != nil || claims == nil || claims.UserID == 0 || claims.Role == "" {
			return 0, "", false
		}

		if claims.Role != "technician" && claims.Role != "customer" {
			return 0, "", false
		}
		return claims.UserID, claims.Role, true
	}

	wsHandler := realtime.NewWSHandler(r.hub, verifyFn)

	r.app.Get("/ws/technicians",
		func(c fiber.Ctx) error {
			if websocket.IsWebSocketUpgrade(c) {
				return c.Next()
			}
			return fiber.ErrUpgradeRequired
		},

		websocket.New(wsHandler.TechnicianWS),
	)

	r.app.Get("/ws/customers",
		func(c fiber.Ctx) error {
			if websocket.IsWebSocketUpgrade(c) {
				return c.Next()
			}
			return fiber.ErrUpgradeRequired
		},
		websocket.New(wsHandler.CustomerWS),
	)
}

// setupSharedResources configures resources available to all authenticated users
func (r *Router) setupSharedResources(api fiber.Router) {
	r.container.NotificationHandler.RegisterRoutes(api)
	r.container.ProvinceHandler.RegisterRoutes(api)
	r.container.DistrictHandler.RegisterRoutes(api)
	r.container.SubDistrictHandler.RegisterRoutes(api)
	r.container.ServiceCategoryHandler.RegisterRoutes(api)
	r.container.ServiceHandler.RegisterRoutes(api)
	r.container.BadgeHandler.RegisterRoutes(api)
	r.container.BookingHandler.RegisterRoutes(api)
	r.container.TimeSlotHandler.RegisterRoutes(api)

	// OCR functionality
	ocrroutes.RegisterOCRRoutes(api, r.container.OCRHandler)
}

// func (r *Router) setupCustomerRoutes(api fiber.Router) {
// 	customers := api.Group("/customers")
// }

func (r *Router) setupTechnicianPublicRoutes(api fiber.Router) {
	technicians := api.Group("/technicians")

	r.container.TechnicianCalendarHandler.RegisterRoutes(technicians)
	r.container.TechnicianServiceHandler.RegisterRoutes(technicians)
	r.container.TechnicianBadgeHandler.RegisterRoutes(technicians)
	r.container.TechnicianMatchingHandler.RegisterRoutes(technicians)
	r.container.TechnicianHandler.RegisterPublicRoutes(technicians)
	r.container.TechnicianPostHandler.RegisterPublicRoutes(technicians)
}

func (r *Router) setupCustomerMeRoutes(api fiber.Router) {
	me := api.Group("/customers/me", middleware.CustomerOnly())

	r.container.CustomerAddressHandler.RegisterRoutes(me, r.cfg)
	r.container.CustomerHandler.RegisterRoutes(me)
}

func (r *Router) setupTechnicianMeRoutes(api fiber.Router) {
	me := api.Group("/technicians/me", middleware.TechnicianOnly())

	r.container.BookingHandler.RegisterTechnicianRoutes(me)
	r.container.TechnicianHandler.RegisterRoutes(me)
	r.container.TechnicianAddressHandler.RegisterRoutes(me, r.cfg)
	r.container.TechnicianPostHandler.RegisterRoutes(me)
	r.container.TimeSlotHandler.RegisterTechnicianRoutes(me)
	r.container.TechnicianScheduleHandler.RegisterRoutes(me)
}

// setupDevelopmentTools configures development-only endpoints
func (r *Router) setupDevelopmentTools() {
	r.app.Get("/dev/ocr/test", r.handleOCRTestPage)
}

// Health check handlers

func (r *Router) handleRoot(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"service": "changsure-core-service",
		"version": "1.0.0",
		"status":  "operational",
	})
}

func (r *Router) handleHealth(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status": "ok",
	})
}

func (r *Router) handleDetailedHealth(c fiber.Ctx) error {
	dbHealth := r.checkDatabaseHealth()

	status := fiber.StatusOK
	if dbHealth.Status != "healthy" {
		status = fiber.StatusServiceUnavailable
	}

	return c.Status(status).JSON(fiber.Map{
		"status": map[string]string{
			"overall":  dbHealth.Status,
			"database": dbHealth.Status,
		},
	})
}

func (r *Router) handleReadiness(c fiber.Ctx) error {
	dbHealth := r.checkDatabaseHealth()

	if dbHealth.Status != "healthy" {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"ready":  false,
			"reason": dbHealth.Error,
		})
	}

	return c.JSON(fiber.Map{
		"ready": true,
	})
}

func (r *Router) handleLiveness(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"alive": true,
	})
}

// Database health check

type HealthStatus struct {
	Status string
	Error  string
}

func (r *Router) checkDatabaseHealth() HealthStatus {
	sqlDB, err := r.db.DB()
	if err != nil {
		return HealthStatus{
			Status: "unhealthy",
			Error:  "failed to get database instance",
		}
	}

	if err := sqlDB.Ping(); err != nil {
		return HealthStatus{
			Status: "unhealthy",
			Error:  "database ping failed",
		}
	}

	return HealthStatus{
		Status: "healthy",
		Error:  "",
	}
}

// Development tools

func (r *Router) handleOCRTestPage(c fiber.Ctx) error {
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

// 404 handler

func (r *Router) setup404Handler() {
	r.app.Use(r.handle404)
}

func (r *Router) handle404(c fiber.Ctx) error {
	return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
		"error": fiber.Map{
			"code":    "ROUTE_NOT_FOUND",
			"message": "The requested endpoint does not exist",
			"path":    c.Path(),
			"method":  c.Method(),
		},
	})
}

// Utility functions

func (r *Router) logRegisteredRoutes() {
	log.Println("\n=== Registered Routes ===")

	routes := r.app.GetRoutes()
	for _, route := range routes {
		log.Printf("%-7s %s", route.Method, route.Path)
	}

	log.Printf("\nTotal routes: %d\n", len(routes))
	log.Println("========================\n")
}

// Setup is a convenience function for backward compatibility
func Setup(app *fiber.App, cfg *config.Config, db *gorm.DB) {
	router, err := NewRouter(app, cfg, db)
	if err != nil {
		panic(fmt.Errorf("failed to setup routes: %w", err))
	}

	router.Setup()
}
