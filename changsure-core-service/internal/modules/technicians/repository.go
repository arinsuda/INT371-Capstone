package technicians

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

type Repository interface {
	FindByID(ctx context.Context, id uint) (*Technician, error)
	FindByEmail(ctx context.Context, email string) (*Technician, error)
	FindByPhone(ctx context.Context, phone string) (*Technician, error)
	Create(ctx context.Context, m *Technician) error
	Update(ctx context.Context, m *Technician) error

	ExistsByID(ctx context.Context, id uint) (bool, error)
	ExistsByEmail(ctx context.Context, email string) (bool, error)
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &repository{db: db} }

func (r *repository) FindByID(ctx context.Context, id uint) (*Technician, error) {
	var m Technician
	if err := r.db.WithContext(ctx).First(&m, id).Error; err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *repository) FindByEmail(ctx context.Context, email string) (*Technician, error) {
	var m Technician
	if err := r.db.WithContext(ctx).Where("email = ?", email).First(&m).Error; err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *repository) FindByPhone(ctx context.Context, phone string) (*Technician, error) {
	var m Technician
	if err := r.db.WithContext(ctx).Where("phone = ?", phone).First(&m).Error; err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *repository) Create(ctx context.Context, m *Technician) error {
	return r.db.WithContext(ctx).Create(m).Error
}

func (r *repository) Update(ctx context.Context, m *Technician) error {
	return r.db.WithContext(ctx).Save(m).Error
}

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

func (r *repository) ExistsByEmail(ctx context.Context, email string) (bool, error) {
	var m Technician
	if err := r.db.WithContext(ctx).
		Select("id").
		Where("email = ?", email).
		First(&m).Error; err != nil {

		if errors.Is(err, gorm.ErrRecordNotFound) {
			return false, nil
		}
		return false, err
	}
	return true, nil
}
