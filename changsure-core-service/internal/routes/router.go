package routes

import (
	"context"
	"fmt"
	"log/slog"
	"strings"

	"changsure-core-service/internal/config"
	"changsure-core-service/internal/jwtutil"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/modules/jobs"
	ocrroutes "changsure-core-service/internal/modules/ocr/routes"
	"changsure-core-service/internal/realtime"
	"changsure-core-service/internal/registry"

	"github.com/gofiber/contrib/v3/websocket"
	"github.com/gofiber/fiber/v3"
	"gorm.io/gorm"
)

type Router struct {
	app       *fiber.App
	cfg       *config.Config
	db        *gorm.DB
	container *registry.Container
	hub       *realtime.Hub
}

func NewRouter(app *fiber.App, cfg *config.Config, db *gorm.DB) (*Router, error) {
	hub := realtime.NewHub()
	container, err := registry.NewContainer(db, cfg, hub)
	if err != nil {
		return nil, fmt.Errorf("failed to create DI container: %w", err)
	}
	return &Router{app: app, cfg: cfg, db: db, container: container, hub: hub}, nil
}

func (r *Router) Setup() {
	middleware.SetupMiddleware(r.app, r.cfg)

	r.setupHealthRoutes()
	r.setupWebSocketRoutes()
	r.setupPublicRoutes()
	r.setupProtectedRoutes()

	if r.cfg.IsDevelopment() {
		r.setupDevelopmentTools()
		r.logRegisteredRoutes()
	}

	r.setup404Handler()
	r.startBackgroundJobs()
}

func (r *Router) setupHealthRoutes() {
	r.app.Get("/", r.handleRoot)
	r.app.Get("/health", r.handleHealth)
	r.app.Get("/health/detailed", r.handleDetailedHealth)
	r.app.Get("/ready", r.handleReadiness)
	r.app.Get("/alive", r.handleLiveness)
}

func (r *Router) setupPublicRoutes() {
	api := r.app.Group("/api")
	r.container.AuthHandler.RegisterRoutes(api)
	r.container.PaymentHandler.RegisterWebhookRoutes(api)
	r.container.ResetPasswordHandler.RegisterRoutes(api)
	r.container.ProvinceHandler.RegisterRoutes(api)
	r.container.DistrictHandler.RegisterRoutes(api)
	r.container.SubDistrictHandler.RegisterRoutes(api)
	r.container.ServiceCategoryHandler.RegisterRoutes(api)
	r.container.ServiceHandler.RegisterRoutes(api)
	r.container.DocumentHandler.RegisterRoutes(api)

	publicTech := api.Group("/technicians")
	r.container.CriminalCheckHandler.RegisterRoutes(publicTech, r.cfg.JWT.Secret)
}

func (r *Router) setupProtectedRoutes() {
	v1 := r.app.Group("/api", middleware.AuthMiddleware(r.cfg))

	r.setupSharedRoutes(v1)
	r.setupTechnicianRoutes(v1)
	r.setupCustomerRoutes(v1)
	r.setupAdminRoutes(v1)
}

func (r *Router) setupSharedRoutes(api fiber.Router) {
	r.container.NotificationHandler.RegisterRoutes(api)
	r.container.BadgeHandler.RegisterRoutes(api)
	r.container.TimeSlotHandler.RegisterRoutes(api)
	r.container.ChatHandler.RegisterRoutes(api)
	r.container.PaymentHandler.RegisterRoutes(api)
	r.container.DocumentHandler.RegisterAdminRoute(api)
	ocrroutes.RegisterOCRRoutes(api, r.container.OCRHandler)
}

func (r *Router) setupAdminRoutes(api fiber.Router) {
	admin := api.Group("/admins").Use(middleware.AdminOnly())
	r.container.AdminHandler.RegisterRoutes(admin)

	criminal := api.Group("/verification").Use(middleware.AdminOnly())
	r.container.CriminalCheckHandler.RegisterAdminRoutes(criminal)

	technician := api.Group("/admins/:adminID/technicians").Use(middleware.AdminOnly())
	r.container.TechnicianHandler.RegisterAdminRoutes(technician)
	r.container.TechnicianPostHandler.RegisterAdminRoutes(technician)
}

func (r *Router) startBackgroundJobs() {
	cleaner := jobs.NewCleanupJob(r.db, nil)
	go cleaner.Start(context.Background())
	slog.Info("background jobs started", "job", "cleanup_expired_qr")
}

func (r *Router) setupTechnicianRoutes(api fiber.Router) {
	technicians := api.Group("/technicians")

	r.container.TechnicianHandler.RegisterRoutes(technicians)
	r.container.TechnicianPostHandler.RegisterRoutes(technicians)
	r.container.TechnicianBadgeHandler.RegisterRoutes(technicians)
	r.container.TechnicianServiceHandler.RegisterRoutes(technicians)
	r.container.TechnicianMatchingHandler.RegisterRoutes(technicians)
	r.container.TechnicianCalendarHandler.RegisterRoutes(technicians)
	r.container.TechnicianBookingHandler.RegisterRoutes(technicians)
	r.container.TechnicianAddressHandler.RegisterRoutes(technicians)
	r.container.WalletHandler.RegisterRoutes(technicians)
	r.container.TechnicianReviewHandler.RegisterRoutes(technicians)
}

func (r *Router) setupCustomerRoutes(api fiber.Router) {
	customers := api.Group("/customers")

	r.container.CustomerHandler.RegisterRoutes(customers)
	r.container.CustomerBookingHandler.RegisterRoutes(customers)
	r.container.CustomerAddressHandler.RegisterRoutes(customers, r.cfg)
	r.container.CustomerReviewHandler.RegisterRoutes(customers)
}

func (r *Router) setupWebSocketRoutes() {
	verifyToken := r.buildWSTokenVerifier()
	wsHandler := realtime.NewWSHandler(r.hub, verifyToken)

	upgradeOnly := func(c fiber.Ctx) error {
		if websocket.IsWebSocketUpgrade(c) {
			return c.Next()
		}
		return fiber.ErrUpgradeRequired
	}

	r.app.Get("/ws/technicians", upgradeOnly, websocket.New(wsHandler.TechnicianWS))
	r.app.Get("/ws/customers", upgradeOnly, websocket.New(wsHandler.CustomerWS))
}

func (r *Router) buildWSTokenVerifier() func(token string) (uint, string, bool) {
	allowedRoles := map[string]struct{}{
		jwtutil.RoleTechnician: {},
		jwtutil.RoleCustomer:   {},
	}
	return func(token string) (uint, string, bool) {
		token = strings.TrimSpace(strings.TrimPrefix(token, "Bearer "))
		if token == "" {
			return 0, "", false
		}
		claims, err := jwtutil.ParseString(r.cfg.JWT.Secret, token)
		if err != nil || claims == nil || claims.UserID == 0 {
			return 0, "", false
		}
		if _, ok := allowedRoles[claims.Role]; !ok {
			return 0, "", false
		}
		return claims.UserID, claims.Role, true
	}
}

func (r *Router) handleRoot(c fiber.Ctx) error {
	return c.JSON(fiber.Map{"service": "changsure-core-service", "version": "1.0.0", "status": "operational"})
}

func (r *Router) handleHealth(c fiber.Ctx) error {
	return c.JSON(fiber.Map{"status": "ok"})
}

func (r *Router) handleDetailedHealth(c fiber.Ctx) error {
	db := r.checkDatabaseHealth()
	status := fiber.StatusOK
	overall := "healthy"
	if db.status != "healthy" {
		status = fiber.StatusServiceUnavailable
		overall = db.status
	}
	return c.Status(status).JSON(fiber.Map{
		"status": fiber.Map{"overall": overall, "database": db.status},
	})
}

func (r *Router) handleReadiness(c fiber.Ctx) error {
	db := r.checkDatabaseHealth()
	if db.status != "healthy" {
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"ready": false, "reason": db.errMsg})
	}
	return c.JSON(fiber.Map{"ready": true})
}

func (r *Router) handleLiveness(c fiber.Ctx) error {
	return c.JSON(fiber.Map{"alive": true})
}

type dbHealth struct {
	status string
	errMsg string
}

func (r *Router) checkDatabaseHealth() dbHealth {
	sqlDB, err := r.db.DB()
	if err != nil {
		return dbHealth{status: "unhealthy", errMsg: "failed to get database instance"}
	}
	if err := sqlDB.Ping(); err != nil {
		return dbHealth{status: "unhealthy", errMsg: "database ping failed"}
	}
	return dbHealth{status: "healthy"}
}

func (r *Router) setupDevelopmentTools() {
	r.app.Get("/dev/ocr/test", r.handleOCRTestPage)
}

func (r *Router) handleOCRTestPage(c fiber.Ctx) error {
	c.Set("Content-Security-Policy", buildCSP())
	return c.SendFile("./test.html")
}

func buildCSP() string {
	return strings.Join([]string{
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
	}, "; ")
}

func (r *Router) setup404Handler() {
	r.app.Use(func(c fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": fiber.Map{
				"code":    "ROUTE_NOT_FOUND",
				"message": "The requested endpoint does not exist",
				"path":    c.Path(),
				"method":  c.Method(),
			},
		})
	})
}

func (r *Router) logRegisteredRoutes() {
	routes := r.app.GetRoutes()
	slog.Info("registered routes", "total", len(routes))
	for _, route := range routes {
		slog.Debug("route", "method", route.Method, "path", route.Path)
	}
}

func Setup(app *fiber.App, cfg *config.Config, db *gorm.DB) *Router {
	router, err := NewRouter(app, cfg, db)
	if err != nil {
		panic(fmt.Errorf("failed to initialise router: %w", err))
	}
	router.Setup()
	return router
}

func (r *Router) Hub() *realtime.Hub {
	return r.hub
}
