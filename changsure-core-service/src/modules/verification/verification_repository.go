package verification

import "gorm.io/gorm"

type Repository interface {
	Create(v *TechnicianVerification) error
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &repository{db: db} }

func (r *repository) Create(v *TechnicianVerification) error {
	return r.db.Create(v).Error
}
