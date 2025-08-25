package database

import (
	"fmt"
	"log"
	"time"

	"changsure-core-service/configs"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"gorm.io/gorm/schema"
)

type Database struct {
	DB *gorm.DB
}

var DB *Database

// Connect initializes database connection
func Connect(config *configs.Config) (*gorm.DB, error) {
	// 1) Validate config first
	if err := config.ValidateDatabaseConfig(); err != nil {
		return nil, fmt.Errorf("invalid database config: %w", err)
	}

	// 2) Build DSN
	dsn := config.GetDatabaseDSN()
	if dsn == "" {
		return nil, fmt.Errorf("unsupported database driver: %s", config.Database.Driver)
	}

	// 3) GORM config
	gormConfig := &gorm.Config{
		Logger: getLoggerMode(config.App.Environment),
		// ถ้าต้องการใช้ชื่อตารางเอกพจน์ (user ไม่ใช่ users)
		// NamingStrategy: schema.NamingStrategy{ SingularTable: true },
		NamingStrategy: schema.NamingStrategy{
			// ตั้งค่าอื่น ๆ ได้ เช่น TablePrefix: "cap_",
			// หรือใช้ค่า default ก็ได้
		},
	}

	// 4) Open connection
	var (
		db  *gorm.DB
		err error
	)

	switch config.Database.Driver {
	case "mysql":
		db, err = gorm.Open(mysql.Open(dsn), gormConfig)
	default:
		return nil, fmt.Errorf("unsupported database driver: %s", config.Database.Driver)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// 5) Configure pool
	if err := configureConnectionPool(db, config); err != nil {
		return nil, fmt.Errorf("failed to configure connection pool: %w", err)
	}

	// 6) Ping
	if err := testConnection(db); err != nil {
		return nil, fmt.Errorf("failed to test database connection: %w", err)
	}

	// 7) Set global
	DB = &Database{DB: db}
	log.Println("✅ Database connected successfully")
	return db, nil
}

// configureConnectionPool sets up connection pool settings
func configureConnectionPool(db *gorm.DB, config *configs.Config) error {
	sqlDB, err := db.DB()
	if err != nil {
		return err
	}

	sqlDB.SetMaxOpenConns(config.Database.MaxOpenConns)
	sqlDB.SetMaxIdleConns(config.Database.MaxIdleConns)
	sqlDB.SetConnMaxLifetime(config.GetConnectionMaxLifetime())
	// กัน connection ค้างใน pool นานเกินไป (เช่น NAT/Firewall ตัด)
	sqlDB.SetConnMaxIdleTime(30 * time.Minute)

	return nil
}

// testConnection tests database connection
func testConnection(db *gorm.DB) error {
	sqlDB, err := db.DB()
	if err != nil {
		return err
	}
	return sqlDB.Ping()
}

// getLoggerMode returns appropriate logger mode based on environment
func getLoggerMode(environment string) logger.Interface {
	switch environment {
	case "production":
		return logger.Default.LogMode(logger.Error)
	case "development":
		return logger.Default.LogMode(logger.Info)
	default:
		return logger.Default.LogMode(logger.Warn)
	}
}

// AutoMigrate runs database migrations
func AutoMigrate(db *gorm.DB, models ...interface{}) error {
	log.Println("🔄 Running database migrations...")
	for _, model := range models {
		if err := db.AutoMigrate(model); err != nil {
			return fmt.Errorf("failed to migrate model %T: %w", model, err)
		}
	}
	log.Println("✅ Database migrations completed successfully")
	return nil
}

// Close closes database connection
func Close() error {
	if DB == nil || DB.DB == nil {
		return fmt.Errorf("database not initialized")
	}
	sqlDB, err := DB.DB.DB()
	if err != nil {
		return err
	}
	return sqlDB.Close()
}

// GetDB returns current database instance
func GetDB() *gorm.DB {
	if DB == nil || DB.DB == nil {
		log.Fatal("database not initialized")
	}
	return DB.DB
}

// Transaction executes function within database transaction
func Transaction(fn func(*gorm.DB) error) error {
	if DB == nil || DB.DB == nil {
		return fmt.Errorf("database not initialized")
	}
	return DB.DB.Transaction(fn)
}
