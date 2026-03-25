package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"changsure-core-service/internal/config"
	"changsure-core-service/internal/database"
	"changsure-core-service/internal/modules/admin"
	backgroundjob "changsure-core-service/internal/modules/background_job"
	criminalcheck "changsure-core-service/internal/modules/criminal_check"
	"changsure-core-service/internal/modules/jobs"
	"changsure-core-service/internal/modules/notification"
	ocrinfra "changsure-core-service/internal/modules/ocr/infra"
	ocrservice "changsure-core-service/internal/modules/ocr/service"
	"changsure-core-service/internal/modules/technician"
	"changsure-core-service/internal/modules/worker"
	"changsure-core-service/internal/realtime"
	"changsure-core-service/internal/routes"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"

	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"

	"github.com/gofiber/fiber/v3"
	recovermw "github.com/gofiber/fiber/v3/middleware/recover"
	"github.com/joho/godotenv"
)

func main() {
	if err := utils.InitSnowflakeNode(1); err != nil {
		log.Fatalf("Failed to init snowflake node: %v", err)
	}

	if err := validation.Init("th"); err != nil {
		log.Fatalf("Failed to initialize validation: %v", err)
	}

	if err := godotenv.Load(); err != nil {
		log.Println("⚠️  No .env file found, using environment variables")
	}

	cfg := config.LoadConfig()

	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatalf("❌ Failed to connect to database: %v", err)
	}
	defer db.Close()

	if shouldRunMigrations(cfg) {
		log.Println("🔄 Running database migrations...")
		if err := db.MigrateWithExtras(); err != nil {
			log.Fatalf("❌ Migration failed: %v", err)
		}
		if err := db.ApplyExtras(); err != nil {
			log.Fatalf("❌ Apply SQL extras failed: %v", err)
		}
	} else {
		log.Println("⊘ Skipping migrations (production mode)")
	}

	if shouldRunSeed(cfg) {
		log.Println("🌱 Running database seeders...")
		if err := db.Seed(); err != nil {
			log.Fatalf("❌ Seeding failed: %v", err)
		}
	} else {
		log.Println("⊘ Skipping seeders")
	}

	// --- Fiber App ---
	app := fiber.New(fiber.Config{
		AppName:      "Chang Sure API",
		ServerHeader: "Chang Sure",
		ErrorHandler: customErrorHandler,
		BodyLimit:    10 * 1024 * 1024,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
	})

	app.Use(recovermw.New(recovermw.Config{
		EnableStackTrace: true,
	}))

	router := routes.Setup(app, cfg, db.DB)

	workerCtx, workerCancel := context.WithCancel(context.Background())
	defer workerCancel()

	startWorkerPool(workerCtx, db.DB, cfg, router.Hub())

	printStartupInfo(cfg)

	serverErrors := make(chan error, 1)
	go func() {
		addr := ":" + cfg.App.Port
		serverErrors <- app.Listen(addr)
	}()

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

	select {
	case err := <-serverErrors:
		log.Fatalf("❌ Server error: %v", err)

	case sig := <-shutdown:
		log.Printf("🛑 Shutting down server... (signal: %v)", sig)

		workerCancel()

		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		if err := app.ShutdownWithContext(ctx); err != nil {
			log.Fatalf("❌ Graceful shutdown failed: %v", err)
		}

		log.Println("👋 Server stopped gracefully")
	}
}

func startWorkerPool(
	ctx context.Context,
	db *gorm.DB,
	cfg *config.Config,
	hub *realtime.Hub,
) {
	// Redis — ประกอบจาก REDIS_HOST + REDIS_PORT ตาม .env จริง
	redisHost := os.Getenv("REDIS_HOST")
	if redisHost == "" {
		redisHost = "127.0.0.1"
	}
	redisPort := os.Getenv("REDIS_PORT")
	if redisPort == "" {
		redisPort = "6379"
	}
	redisPassword := os.Getenv("REDIS_PASSWORD")
	if redisPassword == "none" {
		redisPassword = ""
	}

	redisClient := redis.NewClient(&redis.Options{
		Addr:     redisHost + ":" + redisPort,
		Password: redisPassword,
		DB:       0,
	})
	if err := redisClient.Ping(ctx).Err(); err != nil {
		log.Fatalf("❌ Worker: failed to connect Redis: %v", err)
	}
	log.Println("✅ Worker Redis connected")

	jobRepo := backgroundjob.NewRepository(db)
	crimRepo := criminalcheck.NewRepository(db)
	techRepo := technician.NewRepository(db)
	notiRepo := notification.NewRepository(db)
	notiSvc := notification.NewService(notiRepo, hub)
	adminRepo := admin.NewRepository(db)
	ocrClient := ocrinfra.NewOCRClient(cfg.OCR.BaseURL)
	ocrSvc := ocrservice.NewOCRService(ocrClient)

	minioStore, err := storage.NewMinioFromConfig(cfg.Minio)
	if err != nil {
		log.Fatalf("❌ Worker: failed to init MinIO: %v", err)
	}

	ocrWorker := worker.NewOCRWorker(worker.OCRWorkerDeps{
		JobRepo:      jobRepo,
		OCRService:   ocrSvc,
		CriminalRepo: crimRepo,
		TechRepo:     techRepo,
		NotiService:  notiSvc,
		Storage:      minioStore,
		Redis:        redisClient,
		Config:       workerConfigFromEnv(),
		AdminRepo:    adminRepo,
	})

	pool := worker.NewPool(ocrWorker)
	go pool.Start(ctx)
	log.Println("✅ Worker pool started")

	banJob := jobs.NewTechnicianBanJob(db, log.Default())
	go banJob.Start(ctx)
	log.Println("✅ Technician ban job started")
}

func workerConfigFromEnv() worker.OCRWorkerConfig {
	cfg := worker.DefaultOCRWorkerConfig()

	if v := os.Getenv("OCR_MAX_CONCURRENT"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			cfg.MaxConcurrent = n
		}
	}
	if v := os.Getenv("OCR_POLL_INTERVAL_SECONDS"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			cfg.PollInterval = time.Duration(n) * time.Second
		}
	}
	if v := os.Getenv("OCR_MANUAL_THRESHOLD_MINUTES"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			cfg.ManualThreshold = time.Duration(n) * time.Minute
		}
	}

	return cfg
}

func shouldRunMigrations(cfg *config.Config) bool {
	switch cfg.App.Environment {
	case "development", "staging":
		return true
	case "production":
		return false
	default:
		return true
	}
}

func shouldRunSeed(cfg *config.Config) bool {
	envSeed := strings.ToLower(os.Getenv("SEED_ON_BOOT"))
	if envSeed == "1" || envSeed == "true" || strings.ToLower(os.Getenv("APP_SEED")) == "true" {
		return true
	}
	switch cfg.App.Environment {
	case "development":
		return false
	default:
		return false
	}
}

func customErrorHandler(c fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError
	message := "Internal Server Error"

	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
		message = e.Message
	}

	if os.Getenv("APP_ENV") == "production" {
		log.Printf("ERROR: [%d] %s - Path: %s", code, message, c.Path())
	}

	return c.Status(code).JSON(fiber.Map{
		"success": false,
		"error": fiber.Map{
			"code":    getErrorCode(code),
			"message": message,
		},
	})
}

func getErrorCode(statusCode int) string {
	switch statusCode {
	case fiber.StatusBadRequest:
		return "BAD_REQUEST"
	case fiber.StatusUnauthorized:
		return "UNAUTHORIZED"
	case fiber.StatusForbidden:
		return "FORBIDDEN"
	case fiber.StatusNotFound:
		return "NOT_FOUND"
	case fiber.StatusRequestEntityTooLarge:
		return "FILE_TOO_LARGE"
	case fiber.StatusUnsupportedMediaType:
		return "UNSUPPORTED_MEDIA_TYPE"
	case fiber.StatusUnprocessableEntity:
		return "UNPROCESSABLE_ENTITY"
	case fiber.StatusInternalServerError:
		return "INTERNAL_ERROR"
	default:
		return "UNKNOWN_ERROR"
	}
}

func printStartupInfo(cfg *config.Config) {
	printBanner()
	log.Printf("✅ Server started successfully")
	log.Printf("📦 Environment: %s", cfg.App.Environment)
	log.Printf("🔌 Port: %s", cfg.App.Port)
	log.Printf("📍 API Base: http://localhost:%s/api/v1", cfg.App.Port)
	log.Printf("💚 Health Check: http://localhost:%s/health", cfg.App.Port)
	log.Printf("📡 WebSocket: ws://localhost:%s/ws/customers", cfg.App.Port)
	fmt.Println()
}

func printBanner() {
	fmt.Println(`
    ________                    _____                 
   / ____/ /_  ____ _____  ____ _/ ___/__  __________ 
  / /   / __ \/ __ '/ __ \/ __ '/ \__ \/ / / / ___/ _ \
 / /___/ / / / /_/ / / / / /_/ / ___/ / /_/ / /  /  __/
 \____/_/ /_/\__,_/_/ /_/\__, / /____/\__,_/_/   \___/ 
                        /____/                         
    `)
}
