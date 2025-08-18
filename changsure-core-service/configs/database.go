package configs

import (
	"fmt"
	"time"
)

// GetDatabaseDSN builds the DSN for the configured driver.
// For MySQL, includes parseTime & loc=Local to map DATETIME → time.Time correctly.
func (c *Config) GetDatabaseDSN() string {
	switch c.Database.Driver {
	case "mysql":
		// utf8mb4 รองรับอีโมจิ/ไทย, parseTime ให้อ่าน TIME/DATE ได้, loc=Local ให้ตรงโซนเครื่อง
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

// GetConnectionMaxLifetime returns connection max lifetime as duration.
func (c *Config) GetConnectionMaxLifetime() time.Duration {
	return time.Duration(c.Database.ConnMaxLifetime) * time.Minute
}

// ValidateDatabaseConfig ensures critical DB config exists before connecting.
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
