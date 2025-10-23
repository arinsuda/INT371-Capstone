package database

import (
	"context"
	"fmt"
	"log"
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
	if dsn == "" {
		return nil, fmt.Errorf("DSN not configured for driver: %s", cfg.Database.Driver)
	}

	gormConfig := &gorm.Config{
		Logger:                 getLoggerMode(cfg.App.Environment),
		SkipDefaultTransaction: true,
		PrepareStmt:            true,
	}

	var db *gorm.DB
	var err error

	switch cfg.Database.Driver {
	case "mysql":
		db, err = gorm.Open(mysql.Open(dsn), gormConfig)
	default:
		return nil, fmt.Errorf("unsupported driver: %s", cfg.Database.Driver)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to connect: %w", err)
	}

	database := &Database{
		DB:     db,
		config: &cfg.Database,
	}

	if err := database.configurePool(); err != nil {
		return nil, fmt.Errorf("failed to configure pool: %w", err)
	}

	if err := database.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping: %w", err)
	}

	log.Println("✅ Database connected successfully")
	return database, nil
}

func (d *Database) configurePool() error {
	sqlDB, err := d.DB.DB()
	if err != nil {
		return err
	}

	sqlDB.SetMaxOpenConns(d.config.MaxOpenConns)
	sqlDB.SetMaxIdleConns(d.config.MaxIdleConns)

	maxLifetime := time.Duration(d.config.ConnMaxLifetime) * time.Minute
	sqlDB.SetConnMaxLifetime(maxLifetime)
	sqlDB.SetConnMaxIdleTime(30 * time.Minute)

	return nil
}

func (d *Database) Ping() error {
	sqlDB, err := d.DB.DB()
	if err != nil {
		return err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
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

func (d *Database) Transaction(fn func(*gorm.DB) error) error {
	return d.DB.Transaction(fn)
}

func (d *Database) GetStats() map[string]interface{} {
	sqlDB, err := d.DB.DB()
	if err != nil {
		return map[string]interface{}{"error": err.Error()}
	}

	stats := sqlDB.Stats()
	return map[string]interface{}{
		"max_open_connections": stats.MaxOpenConnections,
		"open_connections":     stats.OpenConnections,
		"in_use":               stats.InUse,
		"idle":                 stats.Idle,
		"wait_count":           stats.WaitCount,
		"wait_duration":        stats.WaitDuration.String(),
		"max_idle_closed":      stats.MaxIdleClosed,
		"max_lifetime_closed":  stats.MaxLifetimeClosed,
	}
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

func (d *Database) Gorm() *gorm.DB {
	return d.DB
}
