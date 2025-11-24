package services

import (
	"context"
	"strings"

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
	db := r.db.WithContext(ctx).Model(&Service{})

	if q.Search != "" {
		s := strings.ToLower(strings.TrimSpace(q.Search))
		like := "%" + s + "%"
		db = db.Where("(LOWER(ser_name) LIKE ? OR LOWER(ser_description) LIKE ?)", like, like)
	}

	if q.CategoryID != nil && *q.CategoryID > 0 {
		db = db.Where("category_id = ?", *q.CategoryID)
	}

	if q.IsActive != nil {
		db = db.Where("is_active = ?", *q.IsActive)
	}

	var total int64
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	sortBy := q.SortBy
	if sortBy == "" {
		sortBy = "created_at"
	}
	sortOrder := strings.ToLower(q.SortOrder)
	if sortOrder != "asc" {
		sortOrder = "desc"
	}
	db = db.Order(sortBy + " " + sortOrder)

	page := q.Page
	if page < 1 {
		page = 1
	}
	pageSize := q.PageSize
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var items []Service
	if err := db.
		Limit(pageSize).
		Offset(offset).
		Preload("Category").
		Find(&items).Error; err != nil {
		return nil, 0, err
	}

	return items, total, nil
}
