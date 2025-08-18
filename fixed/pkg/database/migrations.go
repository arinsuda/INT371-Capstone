package database

import (
	"fixed/src/modules/user"

	"gorm.io/gorm"
)

func RunMigrations(db *gorm.DB) error {
	models := []interface{}{
		&user.User{},

		// Add other models here
	}

	return AutoMigrate(db, models...)
}
