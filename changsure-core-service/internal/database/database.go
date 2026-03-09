package database

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"changsure-core-service/internal/config"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

type Database struct {
	*gorm.DB
	config *config.DatabaseConfig
}

func Connect(cfg *config.Config) (*Database, error) {
	if err := cfg.ValidateDatabaseConfig(); err != nil {
		return nil, fmt.Errorf("invalid database config: %w", err)
	}

	dsn := cfg.GetDatabaseDSN()

	logLevel := logger.Warn
	if cfg.App.Environment == "development" {
		logLevel = logger.Error
	}
	if cfg.App.Environment == "production" {
		logLevel = logger.Error
	}

	gormConfig := &gorm.Config{
		Logger: logger.New(
			log.New(os.Stdout, "\r\n", log.LstdFlags),
			logger.Config{
				SlowThreshold:             200 * time.Millisecond,
				LogLevel:                  logLevel,
				IgnoreRecordNotFoundError: true,
				Colorful:                  cfg.App.Environment == "development",
			},
		),
		SkipDefaultTransaction: true,
		PrepareStmt:            true,
	}

	db, err := gorm.Open(mysql.Open(dsn), gormConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to connect database: %w", err)
	}

	database := &Database{
		DB:     db,
		config: &cfg.Database,
	}

	if err := database.configurePool(); err != nil {
		return nil, err
	}

	if err := database.Ping(); err != nil {
		return nil, fmt.Errorf("initial ping failed: %w", err)
	}

	log.Println("✅ Database connected successfully")
	return database, nil
}

func (d *Database) configurePool() error {
	sqlDB, err := d.DB.DB()
	if err != nil {
		return fmt.Errorf("failed to get sql.db: %w", err)
	}

	sqlDB.SetMaxOpenConns(d.config.MaxOpenConns)
	sqlDB.SetMaxIdleConns(d.config.MaxIdleConns)
	sqlDB.SetConnMaxLifetime(time.Duration(d.config.ConnMaxLifetime) * time.Minute)
	sqlDB.SetConnMaxIdleTime(30 * time.Minute)

	return nil
}

func (d *Database) Ping() error {
	sqlDB, err := d.DB.DB()
	if err != nil {
		return err
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	return sqlDB.PingContext(ctx)
}

func (d *Database) Close() error {
	sqlDB, err := d.DB.DB()
	if err != nil {
		return err
	}
	return sqlDB.Close()
}
