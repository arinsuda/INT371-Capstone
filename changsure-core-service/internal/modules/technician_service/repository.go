package technicianservice

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

type Repository interface {
	Upsert(ctx context.Context, p *TechnicianService) error
	Search(ctx context.Context, q SearchTechniciansQuery) ([]SearchTechnicianItem, int64, error)
	ReplaceAll(ctx context.Context, tx *gorm.DB, techID uint, items []ServicePatchItem) error
	GetPricing(ctx context.Context, techID, serviceID uint) (*TechnicianService, error)
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &repository{db: db} }

func (r *repository) Upsert(ctx context.Context, p *TechnicianService) error {
	if p.PricingType == "FIXED" && p.PriceFixed == nil {
		return errors.New("price_fixed is required for FIXED pricing type")
	}
	if p.PricingType == "RANGE" {
		if p.PriceMin == nil || p.PriceMax == nil {
			return errors.New("price_min and price_max are required for RANGE pricing type")
		}
		if *p.PriceMin > *p.PriceMax {
			return errors.New("price_min must not exceed price_max")
		}
		if *p.PriceMin == *p.PriceMax {
			return errors.New("price_min and price_max must not be equal, use FIXED pricing instead")
		}
	}
	return r.db.WithContext(ctx).Save(p).Error
}

func (r *repository) GetPricing(ctx context.Context, techID, serviceID uint) (*TechnicianService, error) {
	var pricing TechnicianService
	err := r.db.WithContext(ctx).
		Where("technician_id = ? AND service_id = ? AND is_active = 1", techID, serviceID).
		First(&pricing).Error
	if err != nil {
		return nil, err
	}
	return &pricing, nil
}

func (r *repository) Search(ctx context.Context, q SearchTechniciansQuery) ([]SearchTechnicianItem, int64, error) {
	base := r.db.WithContext(ctx).
		Table("technicians AS t").
		Joins("JOIN technician_services ts ON ts.technician_id = t.id AND ts.is_active = 1").
		Joins("JOIN services s ON s.id = ts.service_id AND s.is_active = 1").
		Joins("LEFT JOIN technician_service_areas tsa ON tsa.technician_id = t.id AND tsa.is_active = 1").
		Where("s.id = ?", q.ServiceID)

	base = applySearchFilters(base, q)

	var total int64
	if err := base.Distinct("t.id").Count(&total).Error; err != nil {
		return nil, 0, err
	}

	orderClause := searchOrderClause(q.Sort)
	var items []SearchTechnicianItem
	err := base.
		Select(`t.id, t.firstname, t.lastname, t.avatar_url,
		        t.rating_avg, t.rating_count,
		        COALESCE(ts.price_fixed, ts.price_min) AS price_from`).
		Order(orderClause).
		Limit(q.PageSize).
		Offset((q.Page - 1) * q.PageSize).
		Scan(&items).Error

	return items, total, err
}

func (r *repository) ReplaceAll(ctx context.Context, tx *gorm.DB, techID uint, items []ServicePatchItem) error {
	if tx == nil {
		tx = r.db
	}
	tx = tx.WithContext(ctx)

	var existing []TechnicianService
	if err := tx.Where("technician_id = ?", techID).Find(&existing).Error; err != nil {
		return err
	}

	exMap := make(map[uint]TechnicianService, len(existing))
	for _, e := range existing {
		exMap[e.ServiceID] = e
	}

	for _, item := range items {
		if old, ok := exMap[item.ServiceID]; ok {
			old.PricingType = item.PricingType
			old.PriceFixed = item.PriceFixed
			old.PriceMin = item.PriceMin
			old.PriceMax = item.PriceMax
			old.IsActive = true
			if err := tx.Save(&old).Error; err != nil {
				return err
			}
			delete(exMap, item.ServiceID)
		} else {
			rec := TechnicianService{
				TechnicianID: techID,
				ServiceID:    item.ServiceID,
				PricingType:  item.PricingType,
				PriceFixed:   item.PriceFixed,
				PriceMin:     item.PriceMin,
				PriceMax:     item.PriceMax,
				IsActive:     true,
			}
			if err := tx.Create(&rec).Error; err != nil {
				return err
			}
		}
	}

	for _, old := range exMap {
		var bookingCount int64
		if err := tx.Table("bookings").
			Where("technician_service_id = ?", old.ID).
			Count(&bookingCount).Error; err != nil {
			return err
		}

		if bookingCount > 0 {

			if err := tx.Model(&old).Update("is_active", false).Error; err != nil {
				return err
			}
		} else {
			if err := tx.Delete(&old).Error; err != nil {
				return err
			}
		}
	}

	return nil
}

func applySearchFilters(db *gorm.DB, q SearchTechniciansQuery) *gorm.DB {
	if q.ProvinceID != nil {
		db = db.Where("tsa.province_id = ?", *q.ProvinceID)
	}
	if q.PriceMin != nil {
		db = db.Where(
			"(ts.pricing_type = 'FIXED' AND ts.price_fixed >= ?) OR (ts.pricing_type = 'RANGE' AND ts.price_max >= ?)",
			*q.PriceMin, *q.PriceMin,
		)
	}
	if q.PriceMax != nil {
		db = db.Where(
			"(ts.pricing_type = 'FIXED' AND ts.price_fixed <= ?) OR (ts.pricing_type = 'RANGE' AND ts.price_min <= ?)",
			*q.PriceMax, *q.PriceMax,
		)
	}
	if q.RatingMin != nil {
		db = db.Where("t.rating_avg >= ?", *q.RatingMin)
	}
	return db
}

func searchOrderClause(sort string) string {
	switch sort {
	case "price_asc":
		return "price_from ASC"
	case "price_desc":
		return "price_from DESC"
	default:
		return "t.rating_avg DESC"
	}
}
