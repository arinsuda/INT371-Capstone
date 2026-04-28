package service

import (
	"context"
	"strings"

	"gorm.io/gorm"
)

type PriceRange struct {
	Min float64
	Max float64
}

type PriceAndCount struct {
	ServiceID       uint    `gorm:"column:service_id"`
	MinPrice        float64 `gorm:"column:min_price"`
	MaxPrice        float64 `gorm:"column:max_price"`
	TechnicianCount int     `gorm:"column:technician_count"`
}

type Repository interface {
	Create(ctx context.Context, m *Service) error
	Get(ctx context.Context, id uint) (*Service, error)
	UpdateFields(ctx context.Context, id uint, fields map[string]any) error
	Delete(ctx context.Context, id uint) error
	List(ctx context.Context, q ListQuery) ([]Service, int64, error)
	GetAll(ctx context.Context, q ListQuery) ([]Service, error)
	GetPriceRangeByProvince(ctx context.Context, serviceIDs []uint, provinceID uint) (map[uint]PriceRange, error)
	GetPriceAndCountByProvince(ctx context.Context, serviceIDs []uint, provinceID uint) (map[uint]PriceAndCount, error)
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

func (r *repository) GetAll(ctx context.Context, q ListQuery) ([]Service, error) {
	db := r.db.WithContext(ctx)

	if q.CategoryID != nil {
		db = db.Where("category_id = ?", *q.CategoryID)
	}
	if q.IsActive != nil {
		db = db.Where("is_active = ?", *q.IsActive)
	}

	db = db.Order("id asc")

	var items []Service
	if err := db.Preload("Category").Find(&items).Error; err != nil {
		return nil, err
	}

	return items, nil
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

func (r *repository) GetPriceRangeByProvince(
	ctx context.Context,
	serviceIDs []uint,
	provinceID uint,
) (map[uint]PriceRange, error) {
	type result struct {
		ServiceID uint    `gorm:"column:service_id"`
		MinPrice  float64 `gorm:"column:min_price"`
		MaxPrice  float64 `gorm:"column:max_price"`
	}

	var rows []result
	err := r.db.WithContext(ctx).
		Table("technician_services ts").
		Select(`
            ts.service_id,
            MIN(COALESCE(ts.price_fixed, ts.price_min)) AS min_price,
            MAX(COALESCE(ts.price_fixed, ts.price_max)) AS max_price
        `).
		Joins(`
            JOIN technician_service_areas tsa 
                ON tsa.technician_id = ts.technician_id 
                AND tsa.province_id = ?
                AND tsa.is_active = TRUE
        `, provinceID).
		Where("ts.service_id IN ?", serviceIDs).
		Where("ts.is_active = TRUE").
		Group("ts.service_id").
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}

	m := make(map[uint]PriceRange, len(rows))
	for _, row := range rows {
		m[row.ServiceID] = PriceRange{Min: row.MinPrice, Max: row.MaxPrice}
	}
	return m, nil
}

func (r *repository) GetPriceAndCountByProvince(
	ctx context.Context,
	serviceIDs []uint,
	provinceID uint,
) (map[uint]PriceAndCount, error) {
	if len(serviceIDs) == 0 {
		return map[uint]PriceAndCount{}, nil
	}

	var rows []PriceAndCount
	err := r.db.WithContext(ctx).
		Table("technician_services ts").
		Select(`
            ts.service_id,
            MIN(COALESCE(ts.price_fixed, ts.price_min))  AS min_price,
            MAX(COALESCE(ts.price_fixed, ts.price_max))  AS max_price,
            COUNT(DISTINCT ts.technician_id)             AS technician_count
        `).
		Joins(`
            JOIN technician_service_areas tsa
                ON  tsa.technician_id = ts.technician_id
                AND tsa.province_id   = ?
                AND tsa.is_active     = TRUE
        `, provinceID).
		Joins(`
            JOIN technicians t
                ON  t.id = ts.technician_id
                AND t.verification_status = 'approved'
        `).
		Where("ts.service_id IN ?", serviceIDs).
		Where("ts.is_active = TRUE").
		Group("ts.service_id").
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}

	m := make(map[uint]PriceAndCount, len(rows))
	for _, row := range rows {
		m[row.ServiceID] = row
	}
	return m, nil
}
