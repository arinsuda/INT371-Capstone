package config

import (
	"fmt"
	"time"
)

func (c *Config) GetDatabaseDSN() string {
	switch c.Database.Driver {
	case "mysql":
		return fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
			c.Database.Username,
			c.Database.Password,
			c.Database.Host,
			c.Database.Port,
			c.Database.DatabaseName,
		)
	case "postgres":
		return fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
			c.Database.Host,
			c.Database.Port,
			c.Database.Username,
			c.Database.Password,
			c.Database.DatabaseName,
		)
	default:
		return ""
	}
}

func (c *Config) GetConnectionMaxLifetime() time.Duration {
	return time.Duration(c.Database.ConnMaxLifetime) * time.Minute
}

func (c *Config) ValidateDatabaseConfig() error {
	if c.Database.Host == "" {
		return fmt.Errorf("database host is required")
	}
	if c.Database.Username == "" {
		return fmt.Errorf("database username is required")
	}
	if c.Database.DatabaseName == "" {
		return fmt.Errorf("database name is required")
	}
	if c.Database.Driver == "" {
		return fmt.Errorf("database driver is required")
	}

	validDrivers := map[string]bool{"mysql": true, "postgres": true}
	if !validDrivers[c.Database.Driver] {
		return fmt.Errorf("unsupported database driver: %s", c.Database.Driver)
	}

	return nil
}
