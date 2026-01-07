package district

import (
	"context"
	"gorm.io/gorm"
)

type Repository interface {
	GetByProvinceID(ctx context.Context, provinceID uint) ([]*District, error)
	GetByID(ctx context.Context, id uint) (*District, error)

	GetBySubDistrictID(ctx context.Context, subDistrictID uint) ([]*District, error)
	Search(ctx context.Context, provinceID *uint, q string, limit int) ([]*District, error)
}

type repo struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repo{db: db}
}

func (r *repo) GetByProvinceID(ctx context.Context, provinceID uint) ([]*District, error) {
	var items []*District
	err := r.db.WithContext(ctx).
		Where("province_id = ?", provinceID).
		Order("name_th ASC").
		Find(&items).Error
	return items, err
}

func (r *repo) GetByID(ctx context.Context, id uint) (*District, error) {
	var d District
	err := r.db.WithContext(ctx).First(&d, id).Error
	return &d, err
}

func (r *repo) GetBySubDistrictID(ctx context.Context, subDistrictID uint) ([]*District, error) {
	var items []*District
	err := r.db.WithContext(ctx).
		Table("districts").
		Joins("JOIN sub_districts ON sub_districts.district_id = districts.id").
		Where("sub_districts.id = ?", subDistrictID).
		Distinct("districts.*").
		Order("districts.name_th ASC").
		Find(&items).Error
	return items, err
}

func (r *repo) Search(ctx context.Context, provinceID *uint, q string, limit int) ([]*District, error) {
	if limit <= 0 || limit > 500 {
		limit = 200
	}
	db := r.db.WithContext(ctx).Model(&District{})
	if provinceID != nil {
		db = db.Where("province_id = ?", *provinceID)
	}
	if q != "" {
		db = db.Where("name_th LIKE ?", "%"+q+"%")
	}
	var items []*District
	err := db.Order("name_th ASC").Limit(limit).Find(&items).Error
	return items, err
}
