package database

import (
	"gorm.io/gorm"
)

func RunMigrations(db *gorm.DB, extra ...interface{}) error {
	models := []interface{}{}
	models = append(models, extra...)

	return AutoMigrate(db, models...)
}
