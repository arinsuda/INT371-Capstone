package services

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, m *Service) error
	Get(ctx context.Context, id uint) (*Service, error)
	UpdateFields(ctx context.Context, id uint, fields map[string]any) error
	Delete(ctx context.Context, id uint) error
	List(ctx context.Context, q ListQuery) ([]Service, int64, error)
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &repository{db: db} }

func (r *repository) Create(ctx context.Context, m *Service) error {
	return r.db.WithContext(ctx).Create(m).Error
}

func (r *repository) Get(ctx context.Context, id uint) (*Service, error) {
	var m Service
	if err := r.db.WithContext(ctx).Preload("Category").First(&m, id).Error; err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *repository) UpdateFields(ctx context.Context, id uint, fields map[string]any) error {
	return r.db.WithContext(ctx).Model(&Service{}).Where("id = ?", id).Updates(fields).Error
}

func (r *repository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&Service{}, id).Error
}

func (r *repository) List(ctx context.Context, q ListQuery) ([]Service, int64, error) {
	db := r.db.WithContext(ctx).Model(&Service{}).Preload("Category")

	if q.CategoryID != nil {
		db = db.Where("category_id = ?", *q.CategoryID)
	}
	if q.Active != nil {
		db = db.Where("is_active = ?", *q.Active)
	}
	if q.Search != "" {
		db = db.Where("ser_name LIKE ?", "%"+q.Search+"%")
	}

	var total int64
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	page, size := q.Page, q.PageSize
	if page <= 0 {
		page = 1
	}
	if size <= 0 || size > 100 {
		size = 20
	}
	offset := (page - 1) * size

	var items []Service
	if err := db.Order("ser_name ASC").Offset(offset).Limit(size).Find(&items).Error; err != nil {
		return nil, 0, err
	}
	return items, total, nil
}
