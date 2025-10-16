package database

import (
	"changsure-core-service/pkg/registry"
	"gorm.io/gorm"
)

func RunMigrations(db *gorm.DB, extra ...interface{}) error {
	models := registry.AllModels()
	models = append(models, extra...)

	return AutoMigrate(db, models...)
}