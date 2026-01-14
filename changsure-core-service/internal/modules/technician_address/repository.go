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
	SetPrimaryAndCreate(ctx context.Context, addr *TechnicianAddress) error

	FindNearby(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error)
	GetTechnicianPhone(ctx context.Context, techID uint) (*string, error)
}

type repo struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repo{db: db}
}

func (r *repo) Create(ctx context.Context, addr *TechnicianAddress) error {
	return r.db.WithContext(ctx).Create(addr).Error
}

func (r *repo) Update(ctx context.Context, addr *TechnicianAddress) error {
	return r.db.WithContext(ctx).Save(addr).Error
}

func (r *repo) Delete(ctx context.Context, id uint, techID uint) error {
	return r.db.WithContext(ctx).
		Where("id = ? AND technician_id = ?", id, techID).
		Delete(&TechnicianAddress{}).Error
}

func (r *repo) Get(ctx context.Context, id uint, techID uint) (*TechnicianAddress, error) {
	var addr TechnicianAddress
	err := r.db.WithContext(ctx).
		Preload("SubDistrict").
		Preload("District").
		Preload("Province").
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
		Preload("SubDistrict").
		Preload("District").
		Preload("Province").
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
            t.technician_id,
            %s AS distance_km,
            p.name_th AS province,
            d.name_th AS district
        FROM technician_addresses t
        LEFT JOIN provinces p ON t.province_id = p.id
        LEFT JOIN districts d ON t.district_id = d.id
        WHERE t.latitude IS NOT NULL AND t.longitude IS NOT NULL
        HAVING distance_km <= ?
        ORDER BY distance_km ASC
        LIMIT ?
    `, distanceFormula)

	var results []addressshared.NearbyTechnicianResult

	err := r.db.Raw(sql, q.Lat, q.Lng, q.Lat, q.KM, q.Limit).Scan(&results).Error
	return results, err
}

func (r *repo) SetPrimaryAndCreate(ctx context.Context, addr *TechnicianAddress) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Model(&TechnicianAddress{}).
			Where("technician_id = ?", addr.TechnicianID).
			Update("is_primary", false).Error; err != nil {
			return err
		}
		if err := tx.Create(addr).Error; err != nil {
			return err
		}
		return nil
	})
}

func (r *repo) GetTechnicianPhone(ctx context.Context, techID uint) (*string, error) {
	var phone *string
	err := r.db.WithContext(ctx).Table("technicians").
		Select("phone").
		Where("id = ?", techID).
		Scan(&phone).Error
	return phone, err
}
