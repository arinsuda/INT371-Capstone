package subdistrict

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

type Repository interface {
	GetByDistrictID(ctx context.Context, districtID uint) ([]*SubDistrict, error)
	GetByID(ctx context.Context, id uint) (*SubDistrict, error)

	GetByProvinceID(ctx context.Context, provinceID uint) ([]*SubDistrict, error)
	Search(ctx context.Context, districtID, provinceID *uint, q string, limit int) ([]*SubDistrict, error)
}

type repo struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repo{db: db}
}

func (r *repo) GetByDistrictID(ctx context.Context, districtID uint) ([]*SubDistrict, error) {
	var items []*SubDistrict
	err := r.db.WithContext(ctx).
		Preload("District").
		Where("district_id = ?", districtID).
		Order("name_th ASC").
		Find(&items).Error
	return items, err
}

func (r *repo) GetByID(ctx context.Context, id uint) (*SubDistrict, error) {
	var s SubDistrict
	err := r.db.WithContext(ctx).
		Preload("District").
		First(&s, id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &s, nil
}

func (r *repo) GetByProvinceID(ctx context.Context, provinceID uint) ([]*SubDistrict, error) {
	var items []*SubDistrict
	err := r.db.WithContext(ctx).
		Preload("District").
		Table("sub_districts").
		Joins("JOIN districts ON districts.id = sub_districts.district_id").
		Where("districts.province_id = ?", provinceID).
		Order("sub_districts.name_th ASC").
		Find(&items).Error
	return items, err
}

func (r *repo) Search(ctx context.Context, districtID, provinceID *uint, q string, limit int) ([]*SubDistrict, error) {
	if limit <= 0 || limit > 500 {
		limit = 200
	}
	db := r.db.WithContext(ctx).
		Preload("District").
		Table("sub_districts")

	if provinceID != nil {
		db = db.Joins("JOIN districts ON districts.id = sub_districts.district_id").
			Where("districts.province_id = ?", *provinceID)
	}
	if districtID != nil {
		db = db.Where("sub_districts.district_id = ?", *districtID)
	}
	if q != "" {
		db = db.Where("sub_districts.name_th LIKE ?", "%"+q+"%")
	}

	var items []*SubDistrict
	err := db.Order("sub_districts.name_th ASC").Limit(limit).Find(&items).Error
	return items, err
}
