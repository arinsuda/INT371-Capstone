package technicianmatching

import (
	"context"
	"fmt"

	custaddr "changsure-core-service/internal/modules/customer_address"
	technicians "changsure-core-service/internal/modules/technician"
	techaddr "changsure-core-service/internal/modules/technician_address"

	"gorm.io/gorm"
)

type TechnicianWithDistance struct {
	technicians.Technician
	DistanceMeters float64 `gorm:"column:distance_meters"`
}

type Repository interface {
	SearchTechnicians(ctx context.Context, custLat, custLng float64, q TechnicianSearchQuery) ([]TechnicianWithDistance, int64, error)
	FindByID(ctx context.Context, id uint) (*technicians.Technician, error)
	GetCustomerPrimaryAddress(ctx context.Context, customerID uint) (float64, float64, error)
	GetTechnicianPrimaryAddress(ctx context.Context, techID uint) (float64, float64, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

var allowedSortOrders = map[string]string{
	"dist_asc":    "distance_meters ASC",
	"dist_desc":   "distance_meters DESC",
	"price_asc":   "technicians.id ASC",
	"rating_desc": "technicians.rating_avg DESC",
	"random":      "RAND()",
}

func (r *repository) SearchTechnicians(
	ctx context.Context,
	custLat, custLng float64,
	q TechnicianSearchQuery,
) ([]TechnicianWithDistance, int64, error) {

	customerPoint := fmt.Sprintf("ST_GeomFromText('POINT(%f %f)', 4326)", custLat, custLng)
	techPoint := "ST_GeomFromText(CONCAT('POINT(', ANY_VALUE(ta.latitude), ' ', ANY_VALUE(ta.longitude), ')'), 4326)"
	distanceExpr := fmt.Sprintf("ST_Distance_Sphere(%s, %s)", techPoint, customerPoint)

	tx := r.db.WithContext(ctx).
		Model(&technicians.Technician{}).
		Joins("INNER JOIN technician_addresses ta ON ta.technician_id = technicians.id AND ta.is_primary = TRUE").
		Preload("Services", "is_active = TRUE").
		Preload("Services.Service").
		Preload("Services.Service.Category").
		Preload("Badges.Badge").
		Preload("ServiceAreas.Province")

	tx = applyFilters(tx, q)

	var total int64
	if err := tx.Session(&gorm.Session{}).Distinct("technicians.id").Count(&total).Error; err != nil {
		return nil, 0, err
	}

	orderClause, ok := allowedSortOrders[q.Sort]
	if !ok {
		orderClause = allowedSortOrders["dist_asc"]
	}

	var list []TechnicianWithDistance
	err := tx.
		Select("technicians.*, " + distanceExpr + " AS distance_meters").
		Group("technicians.id").
		Order(orderClause).
		Limit(q.PageSize).
		Offset((q.Page - 1) * q.PageSize).
		Find(&list).Error

	return list, total, err
}

func applyFilters(tx *gorm.DB, q TechnicianSearchQuery) *gorm.DB {

	tx = tx.Where("technicians.verification_status = ?", technicians.StatusApproved)
	if q.ServiceID != nil {
		tx = tx.Joins(
			"JOIN technician_services ts ON ts.technician_id = technicians.id AND ts.service_id = ? AND ts.is_active = TRUE",
			*q.ServiceID,
		)
		if q.MinPrice != nil {
			tx = tx.Where("(ts.price_min >= ? OR ts.price_fixed >= ?)", *q.MinPrice, *q.MinPrice)
		}
		if q.MaxPrice != nil {
			tx = tx.Where("(ts.price_max <= ? OR ts.price_fixed <= ?)", *q.MaxPrice, *q.MaxPrice)
		}
	}
	if q.ProvinceID != nil {
		tx = tx.Joins(
			"JOIN technician_service_areas tsa ON tsa.technician_id = technicians.id AND tsa.province_id = ? AND tsa.is_active = TRUE",
			*q.ProvinceID,
		)
	}
	if q.MinRating != nil {
		tx = tx.Where("technicians.rating_avg >= ?", *q.MinRating)
	}
	return tx
}

func (r *repository) FindByID(ctx context.Context, id uint) (*technicians.Technician, error) {
	var t technicians.Technician
	err := r.db.WithContext(ctx).
		Preload("Services.Service").
		Preload("Services.Service.Category").
		Preload("ServiceAreas.Province").
		Preload("Badges.Badge").
		Preload("Addresses", "is_primary = TRUE").
		First(&t, id).Error
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (r *repository) GetCustomerPrimaryAddress(ctx context.Context, customerID uint) (float64, float64, error) {
	var addr custaddr.CustomerAddress
	err := r.db.WithContext(ctx).
		Where("customer_id = ? AND is_primary = TRUE", customerID).
		First(&addr).Error
	if err != nil {
		return 0, 0, err
	}
	return *addr.Latitude, *addr.Longitude, nil
}

func (r *repository) GetTechnicianPrimaryAddress(ctx context.Context, techID uint) (float64, float64, error) {
	var addr techaddr.TechnicianAddress
	err := r.db.WithContext(ctx).
		Where("technician_id = ? AND is_primary = TRUE", techID).
		First(&addr).Error
	if err != nil {
		return 0, 0, err
	}
	return *addr.Latitude, *addr.Longitude, nil
}
