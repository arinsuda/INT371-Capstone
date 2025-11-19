package technicians

import (
	"context"
	"errors"
	"gorm.io/gorm"
)

type Repository interface {
	FindByID(id uint) (*Technician, error)
	FindByEmail(email string) (*Technician, error)
	FindByPhone(phone string) (*Technician, error)
	Create(m *Technician) error
	Update(m *Technician) error

	ExistsByID(ctx context.Context, id uint) (bool, error)
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &repository{db: db} }

func (r *repository) FindByID(id uint) (*Technician, error) {
	var m Technician
	if err := r.db.First(&m, id).Error; err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *repository) FindByEmail(email string) (*Technician, error) {
	var m Technician
	if err := r.db.Where("email = ?", email).First(&m).Error; err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *repository) FindByPhone(phone string) (*Technician, error) {
	var m Technician
	if err := r.db.Where("phone = ?", phone).First(&m).Error; err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *repository) Create(m *Technician) error { return r.db.Create(m).Error }
func (r *repository) Update(m *Technician) error { return r.db.Save(m).Error }

func (r *repository) ExistsByID(ctx context.Context, id uint) (bool, error) {
	var m Technician
	if err := r.db.WithContext(ctx).
		Select("id").
		First(&m, id).Error; err != nil {

		if errors.Is(err, gorm.ErrRecordNotFound) {
			return false, nil
		}
		return false, err
	}
	return true, nil
}
