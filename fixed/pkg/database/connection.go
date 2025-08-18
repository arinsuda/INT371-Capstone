package database

import (
	"fmt"
	"log"

	"fixed/configs"
	
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

type Database struct {
	DB *gorm.DB
}

var DB *Database

// Connect initializes database connection
func Connect(config *configs.Config) (*gorm.DB, error) {
	// Validate config first
	if err := config.ValidateDatabaseConfig(); err != nil {
		return nil, fmt.Errorf("invalid database config: %w", err)
	}

	var db *gorm.DB
	var err error

	// Get DSN
	dsn := config.GetDatabaseDSN()
	if dsn == "" {
		return nil, fmt.Errorf("unsupported database driver: %s", config.Database.Driver)
	}

	// Setup GORM config
	gormConfig := &gorm.Config{
		Logger: getLoggerMode(config.App.Environment),
	}

	// Connect based on driver
	switch config.Database.Driver {
	case "mysql":
		db, err = gorm.Open(mysql.Open(dsn), gormConfig)
	default:
		return nil, fmt.Errorf("unsupported database driver: %s", config.Database.Driver)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// Configure connection pool
	if err := configureConnectionPool(db, config); err != nil {
		return nil, fmt.Errorf("failed to configure connection pool: %w", err)
	}

	// Test connection
	if err := testConnection(db); err != nil {
		return nil, fmt.Errorf("failed to test database connection: %w", err)
	}

	// Set global DB
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

	// Set connection pool settings
	sqlDB.SetMaxOpenConns(config.Database.MaxOpenConns)
	sqlDB.SetMaxIdleConns(config.Database.MaxIdleConns)
	sqlDB.SetConnMaxLifetime(config.GetConnectionMaxLifetime())

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
	if DB != nil {
		sqlDB, err := DB.DB.DB()
		if err != nil {
			return err
		}
		return sqlDB.Close()
	}
	return nil
}

// GetDB returns current database instance
func GetDB() *gorm.DB {
	if DB == nil {
		log.Fatal("Database not initialized")
	}
	return DB.DB
}

// Transaction executes function within database transaction
func Transaction(fn func(*gorm.DB) error) error {
	return DB.DB.Transaction(fn)
}

