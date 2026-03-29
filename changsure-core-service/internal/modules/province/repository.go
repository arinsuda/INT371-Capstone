package province

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, p *Province) error
	Update(ctx context.Context, p *Province) error
	Delete(ctx context.Context, id uint) error
	GetByID(ctx context.Context, id uint) (*Province, error)
	GetAll(ctx context.Context) ([]*Province, error)
	Count(ctx context.Context) (int64, error)

	GetByDistrictID(ctx context.Context, districtID uint) ([]*Province, error)
	GetBySubDistrictID(ctx context.Context, subDistrictID uint) ([]*Province, error)
	Search(ctx context.Context, q string, limit int) ([]*Province, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Create(ctx context.Context, p *Province) error {
	return r.db.WithContext(ctx).Create(p).Error
}

func (r *repository) Update(ctx context.Context, p *Province) error {
	return r.db.WithContext(ctx).
		Model(&Province{}).Where("id = ?", p.ID).
		Updates(map[string]any{"name_th": p.NameTH}).Error
}

func (r *repository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&Province{}, id).Error
}

func (r *repository) GetByID(ctx context.Context, id uint) (*Province, error) {
	var p Province
	if err := r.db.WithContext(ctx).First(&p, id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &p, nil
}

func (r *repository) GetAll(ctx context.Context) ([]*Province, error) {
	var items []*Province
	if err := r.db.WithContext(ctx).
		Order("id ASC").
		Find(&items).Error; err != nil {
		return nil, err
	}
	return items, nil
}

func (r *repository) Count(ctx context.Context) (int64, error) {
	var n int64
	if err := r.db.WithContext(ctx).Model(&Province{}).Count(&n).Error; err != nil {
		return 0, err
	}
	return n, nil
}

func (r *repository) GetByDistrictID(ctx context.Context, districtID uint) ([]*Province, error) {
	var items []*Province
	err := r.db.WithContext(ctx).
		Table("provinces").
		Joins("JOIN districts ON districts.province_id = provinces.id").
		Where("districts.id = ?", districtID).
		Distinct("provinces.*").
		Order("provinces.id ASC").
		Find(&items).Error
	return items, err
}

func (r *repository) GetBySubDistrictID(ctx context.Context, subDistrictID uint) ([]*Province, error) {
	var items []*Province
	err := r.db.WithContext(ctx).
		Table("provinces").
		Joins("JOIN districts ON districts.province_id = provinces.id").
		Joins("JOIN sub_districts ON sub_districts.district_id = districts.id").
		Where("sub_districts.id = ?", subDistrictID).
		Distinct("provinces.*").
		Order("provinces.id ASC").
		Find(&items).Error
	return items, err
}

func (r *repository) Search(ctx context.Context, q string, limit int) ([]*Province, error) {
	if limit <= 0 || limit > 500 {
		limit = 200
	}
	var items []*Province
	err := r.db.WithContext(ctx).
		Where("name_th LIKE ?", "%"+q+"%").
		Order("id ASC").
		Limit(limit).
		Find(&items).Error
	return items, err
}
