package technician_services

import (
	"errors"
	"gorm.io/gorm"
)

// ใช้ struct ภายใน package เพื่อตัดวงจร import
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
		Joins("JOIN technician_service_areas tsa ON tsa.technician_id = t.id AND tsa.is_active = 1").
		Joins("JOIN technician_services ts ON ts.technician_service_areas_id = tsa.id AND ts.is_active = 1").
		Joins("JOIN services s ON s.id = ts.service_id AND s.is_active = 1").
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

	// นับจำนวน technician แบบ distinct
	if err := db.Distinct("t.id").Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// เลือกคอลัมน์ให้แมปกับ SearchTechnician
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

	// pagination
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
