package configs

import (
	"fmt"
	"time"
)

// GetDatabaseDSN returns database connection string
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
	default:
		return ""
	}
}

// GetConnectionMaxLifetime returns connection max lifetime as duration
func (c *Config) GetConnectionMaxLifetime() time.Duration {
	return time.Duration(c.Database.ConnMaxLifetime) * time.Minute
}

// ValidateDatabaseConfig validates database configuration
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
	return nil
}