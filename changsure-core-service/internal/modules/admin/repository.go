package admin

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, a *Admin) error
	Update(ctx context.Context, a *Admin) error
	FindByEmail(ctx context.Context, email string) (*Admin, error)
	FindByID(ctx context.Context, id uint) (*Admin, error)
	FindAll(ctx context.Context) ([]Admin, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Create(ctx context.Context, a *Admin) error {
	return r.db.WithContext(ctx).Create(a).Error
}

func (r *repository) Update(ctx context.Context, a *Admin) error {
	return r.db.WithContext(ctx).Save(a).Error
}

func (r *repository) FindByEmail(ctx context.Context, email string) (*Admin, error) {
	var a Admin
	err := r.db.WithContext(ctx).Where("email = ? AND deleted_at IS NULL", email).First(&a).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &a, err
}

func (r *repository) FindByID(ctx context.Context, id uint) (*Admin, error) {
	var a Admin
	err := r.db.WithContext(ctx).Where("id = ? AND deleted_at IS NULL", id).First(&a).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &a, err
}

func (r *repository) FindAll(ctx context.Context) ([]Admin, error) {
	var admins []Admin
	err := r.db.WithContext(ctx).Where("deleted_at IS NULL").Find(&admins).Error
	return admins, err
}
