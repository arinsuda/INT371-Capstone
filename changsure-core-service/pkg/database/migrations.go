package database

import (
	"changsure-core-service/src/modules/user"

	"gorm.io/gorm"
)

// RunMigrations collects all models and migrates them.
func RunMigrations(db *gorm.DB, extra ...interface{}) error {
	models := []interface{}{
		&user.User{},
	}
	models = append(models, extra...)
	return AutoMigrate(db, models...)
}
