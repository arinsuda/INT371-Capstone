package service_categories

import (
	"context"
	"gorm.io/gorm"
)

type Repository interface {
	List(ctx context.Context) ([]ServiceCategory, error)
	Get(ctx context.Context, id uint) (*ServiceCategory, error)
	UpdateFields(ctx context.Context, id uint, fields map[string]any) error
	Create(ctx context.Context, sc *ServiceCategory) error
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &repository{db: db} }

func (r *repository) List(ctx context.Context) ([]ServiceCategory, error) {
	var items []ServiceCategory
	err := r.db.WithContext(ctx).Where("is_active = 1").Order("cat_name asc").Find(&items).Error
	return items, err
}

func (r *repository) Get(ctx context.Context, id uint) (*ServiceCategory, error) {
	var m ServiceCategory
	if err := r.db.WithContext(ctx).First(&m, id).Error; err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *repository) UpdateFields(ctx context.Context, id uint, fields map[string]any) error {
	return r.db.WithContext(ctx).Model(&ServiceCategory{}).Where("id = ?", id).Updates(fields).Error
}

func (r *repository) Create(ctx context.Context, sc *ServiceCategory) error {
	return r.db.WithContext(ctx).Create(sc).Error
}
