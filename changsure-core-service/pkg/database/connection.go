package database

import (
	"fmt"
	"log"
	"time"

	"fixed/configs"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"gorm.io/gorm/schema"
)

type Database struct {
	DB *gorm.DB
}

var DB *Database

func Connect(config *configs.Config) (*gorm.DB, error) {

	if err := config.ValidateDatabaseConfig(); err != nil {
		return nil, fmt.Errorf("invalid database config: %w", err)
	}

	dsn := config.GetDatabaseDSN()
	if dsn == "" {
		return nil, fmt.Errorf("unsupported database driver: %s", config.Database.Driver)
	}

	gormConfig := &gorm.Config{
		Logger: getLoggerMode(config.App.Environment),

		NamingStrategy: schema.NamingStrategy{},
	}

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

	if err := configureConnectionPool(db, config); err != nil {
		return nil, fmt.Errorf("failed to configure connection pool: %w", err)
	}

	if err := testConnection(db); err != nil {
		return nil, fmt.Errorf("failed to test database connection: %w", err)
	}

	DB = &Database{DB: db}
	log.Println("✅ Database connected successfully")
	return db, nil
}

func configureConnectionPool(db *gorm.DB, config *configs.Config) error {
	sqlDB, err := db.DB()
	if err != nil {
		return err
	}

	sqlDB.SetMaxOpenConns(config.Database.MaxOpenConns)
	sqlDB.SetMaxIdleConns(config.Database.MaxIdleConns)
	sqlDB.SetConnMaxLifetime(config.GetConnectionMaxLifetime())

	sqlDB.SetConnMaxIdleTime(30 * time.Minute)

	return nil
}

func testConnection(db *gorm.DB) error {
	sqlDB, err := db.DB()
	if err != nil {
		return err
	}
	return sqlDB.Ping()
}

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

func GetDB() *gorm.DB {
	if DB == nil || DB.DB == nil {
		log.Fatal("database not initialized")
	}
	return DB.DB
}

func Transaction(fn func(*gorm.DB) error) error {
	if DB == nil || DB.DB == nil {
		return fmt.Errorf("database not initialized")
	}
	return DB.DB.Transaction(fn)
}
