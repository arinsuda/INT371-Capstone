// internal/modules/badge/repo.go
package badge

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

var (
	ErrNotFound = errors.New("badge not found")
)

type Repository interface {
	Create(ctx context.Context, b *Badge) error
	FindByID(ctx context.Context, id uint, includeDeleted bool) (*Badge, error)
	Update(ctx context.Context, b *Badge) error
	Delete(ctx context.Context, id uint) error                 
	Restore(ctx context.Context, id uint) error                
	HardDelete(ctx context.Context, id uint) error             
	List(ctx context.Context, q ListBadgesQuery) ([]Badge, int64, error)
}

type gormRepository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &gormRepository{db: db} }

func (r *gormRepository) Create(ctx context.Context, b *Badge) error {
	return r.db.WithContext(ctx).Create(b).Error
}

func (r *gormRepository) FindByID(ctx context.Context, id uint, includeDeleted bool) (*Badge, error) {
	var b Badge
	db := r.db.WithContext(ctx).Model(&Badge{})
	if includeDeleted {
		db = db.Unscoped()
	}
	if err := db.First(&b, id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return &b, nil
}

func (r *gormRepository) Update(ctx context.Context, b *Badge) error {
	return r.db.WithContext(ctx).Save(b).Error
}

func (r *gormRepository) Delete(ctx context.Context, id uint) error {
	res := r.db.WithContext(ctx).Delete(&Badge{}, id)
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *gormRepository) Restore(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Unscoped().
		Model(&Badge{}).
		Where("id = ?", id).
		Update("deleted_at", nil).Error
}

func (r *gormRepository) HardDelete(ctx context.Context, id uint) error {
	res := r.db.WithContext(ctx).Unscoped().Delete(&Badge{}, id)
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *gormRepository) List(ctx context.Context, q ListBadgesQuery) ([]Badge, int64, error) {
	db := r.db.WithContext(ctx).Model(&Badge{})

	switch {
	case q.OnlyDeleted:
		db = db.Unscoped().Where("deleted_at IS NOT NULL")
	case q.IncludeDeleted:
		db = db.Unscoped()
	default:
		db = db.Where("deleted_at IS NULL")
	}

	if q.Search != "" {
		db = db.Where("name LIKE ?", "%"+q.Search+"%")
	}
	if q.Active != nil {
		db = db.Where("is_active = ?", *q.Active)
	}
	if q.Level != nil {
		db = db.Where("level = ?", *q.Level)
	}

	var total int64
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	page, perPage := normalizePage(q.Page, q.PerPage)
	var items []Badge
	if err := db.Order("id DESC").
		Limit(perPage).
		Offset((page - 1) * perPage).
		Find(&items).Error; err != nil {
		return nil, 0, err
	}
	return items, total, nil
}