package technicianaddress

import (
	"context"
	"errors"
	"fmt"

	addressshared "changsure-core-service/internal/modules/address_shared"
	"gorm.io/gorm"
)

type Repository interface {
	WithTx(tx *gorm.DB) Repository
	Transaction(ctx context.Context, fn func(r Repository) error) error

	Create(ctx context.Context, addr *TechnicianAddress) error
	Update(ctx context.Context, addr *TechnicianAddress) error
	DeleteTx(ctx context.Context, id uint, techID uint) error

	Get(ctx context.Context, id uint, techID uint) (*TechnicianAddress, error)
	ListByTechnician(ctx context.Context, techID uint) ([]*TechnicianAddress, error)
	CountByTechnician(ctx context.Context, techID uint) (int64, error)

	SetPrimaryTx(ctx context.Context, techID uint, addressID uint) error
	FindNextPrimaryCandidateTx(ctx context.Context, techID uint, excludeID uint) (*TechnicianAddress, error)

	FindNearby(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error)
	GetTechnicianPhone(ctx context.Context, techID uint) (*string, error)
}

type repo struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repo{db: db}
}

func (r *repo) WithTx(tx *gorm.DB) Repository {
	return &repo{db: tx}
}

func (r *repo) Transaction(ctx context.Context, fn func(r Repository) error) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		return fn(r.WithTx(tx))
	})
}

func (r *repo) Create(ctx context.Context, addr *TechnicianAddress) error {
	return r.db.WithContext(ctx).Create(addr).Error
}

func (r *repo) Update(ctx context.Context, addr *TechnicianAddress) error {
	return r.db.WithContext(ctx).Save(addr).Error
}

func (r *repo) DeleteTx(ctx context.Context, id uint, techID uint) error {
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
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
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
		Order("is_primary DESC, created_at DESC").
		Find(&out).Error
	return out, err
}

func (r *repo) CountByTechnician(ctx context.Context, techID uint) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&TechnicianAddress{}).
		Where("technician_id = ?", techID).
		Count(&count).Error
	return count, err
}

func (r *repo) SetPrimaryTx(ctx context.Context, techID uint, addressID uint) error {

	if err := r.db.WithContext(ctx).Model(&TechnicianAddress{}).
		Where("technician_id = ?", techID).
		Update("is_primary", false).Error; err != nil {
		return err
	}

	return r.db.WithContext(ctx).Model(&TechnicianAddress{}).
		Where("id = ? AND technician_id = ?", addressID, techID).
		Update("is_primary", true).Error
}

func (r *repo) FindNextPrimaryCandidateTx(ctx context.Context, techID uint, excludeID uint) (*TechnicianAddress, error) {
	var next TechnicianAddress
	err := r.db.WithContext(ctx).
		Where("technician_id = ? AND id <> ?", techID, excludeID).
		Order("created_at DESC").
		First(&next).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &next, nil
}

func (r *repo) GetTechnicianPhone(ctx context.Context, techID uint) (*string, error) {
	var phone *string
	err := r.db.WithContext(ctx).Table("technicians").
		Select("phone").
		Where("id = ?", techID).
		Scan(&phone).Error
	return phone, err
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
		cos(radians(t.latitude)) *
		cos(radians(t.longitude - ?)) +
		sin(radians(?)) *
		sin(radians(t.latitude))
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
		WHERE 
			t.is_primary = true
			AND t.latitude IS NOT NULL 
			AND t.longitude IS NOT NULL
		HAVING distance_km <= ?
		ORDER BY distance_km ASC
		LIMIT ?
	`, distanceFormula)

	var results []addressshared.NearbyTechnicianResult
	err := r.db.WithContext(ctx).
		Raw(sql, q.Lat, q.Lng, q.Lat, q.KM, q.Limit).
		Scan(&results).Error

	return results, err
}
