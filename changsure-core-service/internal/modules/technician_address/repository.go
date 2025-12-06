package technicianaddress

import (
	"context"
	"fmt"

	addressshared "changsure-core-service/internal/modules/address_shared"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, addr *TechnicianAddress) error
	Update(ctx context.Context, addr *TechnicianAddress) error
	Delete(ctx context.Context, id uint, techID uint) error
	Get(ctx context.Context, id uint, techID uint) (*TechnicianAddress, error)
	ListByTechnician(ctx context.Context, techID uint) ([]*TechnicianAddress, error)
	ClearPrimary(ctx context.Context, techID uint) error

	FindNearby(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error)
}

type repo struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repo{db: db}
}

func (r *repo) Create(ctx context.Context, addr *TechnicianAddress) error {
	return r.db.WithContext(ctx).
		Create(addr).Error
}

func (r *repo) Update(ctx context.Context, addr *TechnicianAddress) error {
	return r.db.WithContext(ctx).
		Model(&TechnicianAddress{}).
		Where("id = ? AND technician_id = ?", addr.ID, addr.TechnicianID).
		Updates(map[string]any{
			"house_number": addr.HouseNumber,
			"village":      addr.Village,
			"moo":          addr.Moo,
			"soi":          addr.Soi,
			"road":         addr.Road,

			"sub_district": addr.SubDistrict,
			"district":     addr.District,
			"province":     addr.Province,

			"postal_code": addr.PostalCode,
			"country":     addr.Country,

			"province_id": addr.ProvinceID,
			"latitude":    addr.Latitude,
			"longitude":   addr.Longitude,

			"is_primary": addr.IsPrimary,
		}).Error
}

func (r *repo) Delete(ctx context.Context, id uint, techID uint) error {
	return r.db.WithContext(ctx).
		Where("id = ? AND technician_id = ?", id, techID).
		Delete(&TechnicianAddress{}).Error
}

func (r *repo) Get(ctx context.Context, id uint, techID uint) (*TechnicianAddress, error) {
	var addr TechnicianAddress
	err := r.db.WithContext(ctx).
		Where("id = ? AND technician_id = ?", id, techID).
		First(&addr).Error

	if err != nil {
		return nil, err
	}
	return &addr, nil
}

func (r *repo) ListByTechnician(ctx context.Context, techID uint) ([]*TechnicianAddress, error) {
	var out []*TechnicianAddress
	err := r.db.WithContext(ctx).
		Where("technician_id = ?", techID).
		Order("is_primary DESC").
		Find(&out).Error

	return out, err
}

func (r *repo) ClearPrimary(ctx context.Context, techID uint) error {
	return r.db.WithContext(ctx).
		Model(&TechnicianAddress{}).
		Where("technician_id = ?", techID).
		Update("is_primary", false).Error
}

func (r *repo) FindNearby(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error) {
	if q.Limit <= 0 || q.Limit > 200 {
		q.Limit = 50
	}
	if q.KM <= 0 || q.KM > 300 {
		q.KM = 30
	}

	distanceFormula := `
        (6371 * acos(
            cos(radians(?)) *
            cos(radians(latitude)) *
            cos(radians(longitude - ?)) +
            sin(radians(?)) *
            sin(radians(latitude))
        ))
    `

	sql := fmt.Sprintf(`
        SELECT 
            technician_id,
            %s AS distance_km,
            province,
            district,
            sub_district
        FROM technician_addresses
        WHERE latitude IS NOT NULL AND longitude IS NOT NULL
        HAVING distance_km <= ?
        ORDER BY distance_km ASC
        LIMIT ?
    `, distanceFormula)

	var results []addressshared.NearbyTechnicianResult

	err := r.db.Raw(sql, q.Lat, q.Lng, q.Lat, q.KM, q.Limit).Scan(&results).Error
	return results, err
}
