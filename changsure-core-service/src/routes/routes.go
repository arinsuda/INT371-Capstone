package routes

import (
	"changsure-core-service/configs"
	"changsure-core-service/pkg/middleware"
	"changsure-core-service/src/modules/technical"
	"changsure-core-service/src/modules/user"

	"github.com/gofiber/fiber/v3"
	"gorm.io/gorm"
	"time"
)

// Setup initializes all application routes and middleware
func Setup(app *fiber.App, config *configs.Config, db *gorm.DB) {
	// Setup global middlewares
	middleware.SetupMiddleware(app, config)

	// Health check routes
	setupHealthRoutes(app)

	// API version 1
	api := app.Group("/api/v1")

	// Setup all modules
	setupUserModule(api, db, config)
	setupTechnicalModule(api, db, config)

	// Protected routes group
	protected := api.Group("/protected")
	protected.Use(middleware.AuthMiddleware(config))
	setupProtectedRoutes(protected, db, config)

	// Admin routes group
	admin := api.Group("/admin")
	admin.Use(middleware.AuthMiddleware(config))
	admin.Use(middleware.AdminOnly())
	setupAdminRoutes(admin, db, config)

	// Moderator routes group
	moderator := api.Group("/moderator")
	moderator.Use(middleware.AuthMiddleware(config))
	moderator.Use(middleware.ModeratorOnly())
	setupModeratorRoutes(moderator, db, config)

	// Setup 404 handler (should be last)
	setup404Handler(app)
}

// setupUserModule initializes user module with its own routes
func setupUserModule(api fiber.Router, db *gorm.DB, config *configs.Config) {
	// สร้าง dependencies
	userRepo := user.NewRepository(db, config)
	userService := user.NewService(userRepo, config)
	userHandler := user.NewHandler(userService, config)

	// ให้ module จัดการ routes เอง ผ่าน RegisterRoutes method
	userHandler.RegisterRoutes(api)
}

// setupTechnicalModule initializes technical module with its own routes
func setupTechnicalModule(api fiber.Router, db *gorm.DB, config *configs.Config) {
	// สร้าง dependencies
	techRepo := technical.NewRepository(db, config)
	techService := technical.NewService(techRepo, config)
	techHandler := technical.NewHandler(techService, config)

	// ให้ module จัดการ routes เอง ผ่าง RegisterRoutes method
	techHandler.RegisterRoutes(api)
}

// setupProtectedRoutes สำหรับ routes ที่ต้อง authenticate
func setupProtectedRoutes(protected fiber.Router, db *gorm.DB, config *configs.Config) {
	// Dashboard endpoint
	protected.Get("/dashboard", func(c fiber.Ctx) error {
		userID := c.Locals("userID")
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "Dashboard data retrieved",
			"data": fiber.Map{
				"userID": userID,
				"stats":  getDashboardStats(userID),
			},
		})
	})

	// User activity logs
	protected.Get("/activity", func(c fiber.Ctx) error {
		userID := c.Locals("userID")
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "Activity logs retrieved",
			"data":    getActivityLogs(userID),
		})
	})

	// User statistics
	protected.Get("/stats", func(c fiber.Ctx) error {
		userID := c.Locals("userID")
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "User statistics retrieved",
			"data":    getUserStats(userID),
		})
	})
}

// setupAdminRoutes สำหรับ admin เท่านั้น
func setupAdminRoutes(admin fiber.Router, db *gorm.DB, config *configs.Config) {
	// User management
	userAdmin := admin.Group("/users")
	userAdmin.Get("/", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "All users retrieved",
			"data":    getAllUsers(c),
		})
	})

	userAdmin.Get("/:id", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "User details retrieved",
			"data":    getUserDetails(c.Params("id")),
		})
	})

	userAdmin.Put("/:id/status", func(c fiber.Ctx) error {
		// อัพเดท user status
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "User status updated",
		})
	})

	userAdmin.Delete("/:id", func(c fiber.Ctx) error {
		// ลบ user
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "User deleted successfully",
		})
	})

	// System management
	system := admin.Group("/system")
	system.Get("/stats", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "System statistics retrieved",
			"data":    getSystemStats(),
		})
	})

	system.Get("/logs", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "System logs retrieved",
			"data":    getSystemLogs(),
		})
	})

	system.Post("/maintenance", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "Maintenance mode toggled",
		})
	})

	// Database management
	database := admin.Group("/database")
	database.Post("/backup", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "Database backup initiated",
		})
	})

	database.Get("/migrations", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "Migration status retrieved",
			"data":    getMigrationStatus(),
		})
	})

	database.Post("/migrations/run", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "Migrations executed successfully",
		})
	})
}

// setupModeratorRoutes สำหรับ moderator
func setupModeratorRoutes(moderator fiber.Router, db *gorm.DB, config *configs.Config) {
	// Content moderation
	content := moderator.Group("/content")
	content.Get("/reports", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "Content reports retrieved",
			"data":    getContentReports(),
		})
	})

	content.Put("/reports/:id/resolve", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "Report resolved successfully",
		})
	})

	content.Delete("/posts/:id", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "Content deleted successfully",
		})
	})

	// User moderation
	users := moderator.Group("/users")
	users.Post("/:id/warn", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "Warning sent to user",
		})
	})

	users.Post("/:id/suspend", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "User suspended successfully",
		})
	})

	users.Get("/flagged", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "Flagged users retrieved",
			"data":    getFlaggedUsers(),
		})
	})
}

// setupHealthRoutes สำหรับ health checks
func setupHealthRoutes(app *fiber.App) {
	// Basic health check
	app.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":    "ok",
			"message":   "Server is running",
			"timestamp": time.Now().UTC(),
			"version":   "1.0.0",
		})
	})

	// Detailed health check
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

	// Readiness probe (สำหรับ Kubernetes)
	app.Get("/ready", func(c fiber.Ctx) error {
		if isApplicationReady() {
			return c.JSON(fiber.Map{"status": "ready"})
		}
		return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
			"status": "not_ready",
		})
	})

	// Liveness probe (สำหรับ Kubernetes)
	app.Get("/alive", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":    "alive",
			"timestamp": time.Now().UTC(),
		})
	})
}

// setup404Handler สำหรับจัดการ route ที่ไม่มี
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

// Helper functions - ในการใช้งานจริงควรแยกไปไฟล์อื่น
func getDashboardStats(userID interface{}) interface{} {
	return fiber.Map{
		"totalPosts":    42,
		"totalComments": 128,
		"totalLikes":    89,
		"lastActivity":  time.Now().AddDate(0, 0, -1),
	}
}

func getActivityLogs(userID interface{}) interface{} {
	return []fiber.Map{
		{
			"action":    "login",
			"timestamp": time.Now().AddDate(0, 0, -1),
			"ip":        "192.168.1.1",
			"userAgent": "Mozilla/5.0...",
		},
		{
			"action":    "profile_update",
			"timestamp": time.Now().AddDate(0, 0, -2),
			"ip":        "192.168.1.1",
		},
	}
}

func getUserStats(userID interface{}) interface{} {
	return fiber.Map{
		"profileViews":   1337,
		"contentViews":   5420,
		"followers":      89,
		"following":      156,
		"postsThisMonth": 12,
	}
}

func getAllUsers(c fiber.Ctx) interface{} {
	// ในการใช้งานจริงควรใส่ pagination
	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 10)

	return fiber.Map{
		"users": []fiber.Map{
			{
				"id":        1,
				"username":  "john_doe",
				"email":     "john@example.com",
				"status":    "active",
				"createdAt": time.Now().AddDate(0, -6, 0),
			},
			{
				"id":        2,
				"username":  "jane_smith",
				"email":     "jane@example.com",
				"status":    "active",
				"createdAt": time.Now().AddDate(0, -3, 0),
			},
		},
		"pagination": fiber.Map{
			"page":  page,
			"limit": limit,
			"total": 2,
		},
	}
}

func getUserDetails(userID string) interface{} {
	return fiber.Map{
		"id":       userID,
		"username": "john_doe",
		"email":    "john@example.com",
		"status":   "active",
		"profile": fiber.Map{
			"firstName": "John",
			"lastName":  "Doe",
			"avatar":    "/uploads/avatars/john.jpg",
			"bio":       "Software Developer",
		},
		"stats": fiber.Map{
			"posts":    42,
			"comments": 128,
			"likes":    89,
		},
		"createdAt": time.Now().AddDate(0, -6, 0),
		"updatedAt": time.Now().AddDate(0, 0, -7),
	}
}

func getSystemStats() interface{} {
	return fiber.Map{
		"users": fiber.Map{
			"total":       1337,
			"active":      1200,
			"banned":      5,
			"newThisWeek": 25,
		},
		"content": fiber.Map{
			"totalPosts":    12890,
			"totalComments": 45620,
			"reportsOpen":   12,
		},
		"system": fiber.Map{
			"uptime":      "15d 8h 42m",
			"cpuUsage":    "45%",
			"memoryUsage": "2.1GB / 8GB",
			"diskUsage":   "156GB / 500GB",
		},
	}
}

func getSystemLogs() interface{} {
	return []fiber.Map{
		{
			"level":     "info",
			"message":   "Server started successfully",
			"timestamp": time.Now().AddDate(0, 0, -15),
			"service":   "main",
		},
		{
			"level":     "warning",
			"message":   "High memory usage detected",
			"timestamp": time.Now().AddDate(0, 0, -1),
			"service":   "monitor",
		},
		{
			"level":     "error",
			"message":   "Failed to connect to external API",
			"timestamp": time.Now().AddDate(0, 0, 0),
			"service":   "external",
		},
	}
}

func getMigrationStatus() interface{} {
	return fiber.Map{
		"currentVersion": "2024_08_18_000001",
		"appliedCount":   45,
		"pendingCount":   0,
		"lastMigration":  time.Now().AddDate(0, -1, 0),
		"status":         "up_to_date",
	}
}

func getContentReports() interface{} {
	return []fiber.Map{
		{
			"id":          1,
			"contentType": "post",
			"contentID":   123,
			"reason":      "spam",
			"reporter":    "user_456",
			"status":      "pending",
			"createdAt":   time.Now().AddDate(0, 0, -2),
		},
		{
			"id":          2,
			"contentType": "comment",
			"contentID":   789,
			"reason":      "harassment",
			"reporter":    "user_789",
			"status":      "pending",
			"createdAt":   time.Now().AddDate(0, 0, -1),
		},
	}
}

func getFlaggedUsers() interface{} {
	return []fiber.Map{
		{
			"id":        42,
			"username":  "suspicious_user",
			"reason":    "Multiple spam reports",
			"flaggedAt": time.Now().AddDate(0, 0, -3),
			"flaggedBy": "auto_system",
			"status":    "under_review",
		},
	}
}

func checkDatabaseHealth() string {
	// ในการใช้งานจริงควร ping database
	return "healthy"
}

func checkRedisHealth() string {
	// ในการใช้งานจริงควร ping Redis
	return "healthy"
}

func getMemoryUsage() string {
	// ในการใช้งานจริงควรใช้ runtime.ReadMemStats()
	return "256MB / 1GB"
}

func getUptime() string {
	// ในการใช้งานจริงควรคำนวณจาก start time
	return "15d 8h 42m"
}

func isApplicationReady() bool {
	// ตรวจสอบว่า dependencies พร้อมใช้งานหรือไม่
	// เช่น database connection, Redis connection
	return true
}
