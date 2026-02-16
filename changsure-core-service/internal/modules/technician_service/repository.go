package technicianservice

import (
	"errors"
	"gorm.io/gorm"
)

type SearchTechnician struct {
	ID          uint     `gorm:"column:id"           json:"id"`
	FirstName   string   `gorm:"column:firstname"    json:"firstname"`
	LastName    string   `gorm:"column:lastname"     json:"lastname"`
	AvatarURL   *string  `gorm:"column:avatar_url"   json:"avatar_url,omitempty"`
	RatingAvg   *float64 `gorm:"column:rating_avg"   json:"rating_avg,omitempty"`
	RatingCount uint     `gorm:"column:rating_count" json:"rating_count"`
	PriceFrom   *float64 `gorm:"column:price_from"   json:"price_from,omitempty"`
}

type Repository interface {
	Upsert(p *TechnicianService) error
	Search(q SearchTechniciansQuery) ([]SearchTechnician, int64, error)
	ReplaceAllWithPricing(tx *gorm.DB, techID uint, items []TechnicianServicePatchReq) error
	GetPricing(
		techID uint,
		serviceID uint,
	) (*TechnicianService, error)
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &repository{db: db} }

func (r *repository) Upsert(p *TechnicianService) error {
	if p.PricingType == "FIXED" && p.PriceFixed == nil {
		return errors.New("price_fixed is required for FIXED type")
	}
	if p.PricingType == "RANGE" {
		if p.PriceMin == nil || p.PriceMax == nil || *p.PriceMin > *p.PriceMax {
			return errors.New("invalid price range for RANGE type")
		}
	}
	return r.db.Save(p).Error
}

func (r *repository) Search(q SearchTechniciansQuery) ([]SearchTechnician, int64, error) {
	var (
		items []SearchTechnician
		total int64
	)

	db := r.db.Table("technicians AS t").
		Joins("JOIN technician_services ts ON ts.technician_id = t.id AND ts.is_active = 1").
		Joins("JOIN services s ON s.id = ts.service_id AND s.is_active = 1").
		Joins("LEFT JOIN technician_service_areas tsa ON tsa.technician_id = t.id AND tsa.is_active = 1").
		Where("s.id = ?", q.ServiceID)

	if q.ProvinceID != nil {
		db = db.Where("tsa.province_id = ?", *q.ProvinceID)
	}

	if q.PriceMin != nil {
		db = db.Where(`((ts.pricing_type='FIXED' AND ts.price_fixed >= ?) OR (ts.pricing_type='RANGE' AND ts.price_max >= ?))`, *q.PriceMin, *q.PriceMin)
	}
	if q.PriceMax != nil {
		db = db.Where(`((ts.pricing_type='FIXED' AND ts.price_fixed <= ?) OR (ts.pricing_type='RANGE' AND ts.price_min <= ?))`, *q.PriceMax, *q.PriceMax)
	}
	if q.RatingMin != nil {
		db = db.Where("t.rating_avg >= ?", *q.RatingMin)
	}

	if err := db.Distinct("t.id").Count(&total).Error; err != nil {
		return nil, 0, err
	}

	db = db.Select(`
		t.id, t.firstname, t.lastname, t.avatar_url, 
		t.rating_avg, t.rating_count,
		COALESCE(ts.price_fixed, ts.price_min) AS price_from`)

	switch q.Sort {
	case "price_asc":
		db = db.Order("price_from ASC")
	case "price_desc":
		db = db.Order("price_from DESC")
	default:
		db = db.Order("t.rating_avg DESC")
	}

	if q.Page <= 0 {
		q.Page = 1
	}
	if q.PageSize <= 0 || q.PageSize > 50 {
		q.PageSize = 20
	}
	offset := (q.Page - 1) * q.PageSize

	if err := db.Offset(offset).Limit(q.PageSize).Scan(&items).Error; err != nil {
		return nil, 0, err
	}
	return items, total, nil
}

func (r *repository) ReplaceAllWithPricing(
	tx *gorm.DB,
	techID uint,
	items []TechnicianServicePatchReq,
) error {

	if tx == nil {
		tx = r.db
	}

	var existing []TechnicianService
	if err := tx.
		Where("technician_id = ?", techID).
		Find(&existing).Error; err != nil {
		return err
	}

	exMap := make(map[uint]TechnicianService)
	for _, e := range existing {
		exMap[e.ServiceID] = e
	}

	inMap := make(map[uint]TechnicianServicePatchReq)
	for _, i := range items {
		inMap[i.ServiceID] = i
	}

	// -------------------------
	// UPSERT
	// -------------------------
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

	// -------------------------
	// REMOVE OLD
	// -------------------------
	for _, old := range exMap {

		var count int64
		if err := tx.Table("bookings").
			Where("technician_service_id = ?", old.ID).
			Count(&count).Error; err != nil {
			return err
		}

		if count > 0 {
			// disable instead delete
			if err := tx.Model(&old).
				Update("is_active", false).Error; err != nil {
				return err
			}
			continue
		}

		if err := tx.Delete(&old).Error; err != nil {
			return err
		}
	}

	return nil
}

func (r *repository) GetPricing(
	techID uint,
	serviceID uint,
) (*TechnicianService, error) {

	var pricing TechnicianService

	err := r.db.
		Where("technician_id = ? AND service_id = ? AND is_active = 1",
			techID, serviceID).
		First(&pricing).Error

	if err != nil {
		return nil, err
	}

	return &pricing, nil
}
