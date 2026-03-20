package booking

import (
	"context"
	"errors"
	"fmt"
	"math"
	"time"

	address "changsure-core-service/internal/modules/customer_address"
	techService "changsure-core-service/internal/modules/technician_service"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Repository interface {
	WithTx(tx *gorm.DB) Repository
	Create(ctx context.Context, booking *Booking) error
	CreateImages(ctx context.Context, images []BookingImage) error
	FindByID(ctx context.Context, id uint) (*Booking, error)
	FindByIDForUpdate(ctx context.Context, id uint) (*Booking, error)
	UpdateStatus(ctx context.Context, id uint, status string, updatedAt time.Time) error
	UpdateLastRead(ctx context.Context, bookingID uint, role string, readAt time.Time) error
	GetBookedSlotIDs(ctx context.Context, technicianID uint, date string) ([]uint, error)
	IsSlotBooked(ctx context.Context, technicianID uint, date string, slotID uint) (bool, error)
	GetTechnicianServiceByTechnicianAndService(ctx context.Context, technicianID uint, serviceID uint) (*techService.TechnicianService, error)
	GetCustomerAddress(ctx context.Context, addressID uint, customerID uint) (*address.CustomerAddress, error)
	IsTechnicianServingProvince(ctx context.Context, technicianID uint, provinceID uint) (bool, error)
	MarkAsPaid(ctx context.Context, bookingID uint) error
	UpdateFinalPrice(ctx context.Context, bookingID uint, finalPrice float64) error
	ListByCustomer(ctx context.Context, customerID uint, statuses []string, startDate string, endDate string, offset int, limit int) ([]Booking, int64, error)
	ListByTechnician(ctx context.Context, technicianID uint, statuses []string, startDate string, endDate string, offset int, limit int) ([]Booking, int64, error)

	CreateReview(ctx context.Context, review *Review, images []ReviewImage) error
	FindReviewByBookingID(ctx context.Context, bookingID uint) (*Review, error)
	FindBookingForReview(ctx context.Context, bookingID uint, customerID uint) (*Booking, error)
	UpsertServiceRating(ctx context.Context, serviceID uint) error

	GetTechnicianReviewSummary(ctx context.Context, technicianID uint) (*ReviewSummary, error)
	ListReviewsByTechnician(ctx context.Context, technicianID uint, filter ReviewFilter, offset int, limit int) ([]ReviewWithDetail, int64, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) WithTx(tx *gorm.DB) Repository {
	return &repository{db: tx}
}

func (r *repository) Create(ctx context.Context, booking *Booking) error {
	return r.db.WithContext(ctx).Create(booking).Error
}

func (r *repository) CreateImages(ctx context.Context, images []BookingImage) error {
	return r.db.WithContext(ctx).Create(&images).Error
}

func (r *repository) FindByID(ctx context.Context, id uint) (*Booking, error) {
	var b Booking
	err := r.db.WithContext(ctx).
		Preload("Customer", func(db *gorm.DB) *gorm.DB {
			return db.Select("id", "first_name", "last_name", "phone", "avatar_url")
		}).
		Preload("Images").
		Preload("TimeSlot").
		Preload("Technician").
		Preload("TechnicianService").
		Preload("TechnicianService.Service").
		Preload("TechnicianService.Service.Category").
		First(&b, id).Error
	if err != nil {
		return nil, err
	}

	if b.Status == BookingStatusCompleted {
		type feeRow struct {
			FeeRate   float64
			FeeAmount float64
			NetAmount float64
		}
		var row feeRow
		err := r.db.WithContext(ctx).
			Table("wallet_transactions").
			Select("fee_rate, fee_amount, net_amount").
			Where("booking_id = ? AND category = ?", b.ID, "JOB_PAYMENT").
			Order("created_at DESC").
			Limit(1).
			Scan(&row).Error

		if err == nil && row.NetAmount != 0 {
			b.FeeRate = &row.FeeRate
			b.FeeAmount = &row.FeeAmount
			b.NetAmount = &row.NetAmount
		}
	}

	return &b, nil
}

func (r *repository) FindByIDForUpdate(ctx context.Context, id uint) (*Booking, error) {
	var b Booking
	err := r.db.WithContext(ctx).
		Clauses(clause.Locking{Strength: "UPDATE"}).
		Preload("Technician").
		Preload("TechnicianService.Service").
		Where("id = ?", id).
		First(&b).Error

	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &b, err
}

func (r *repository) UpdateStatus(ctx context.Context, id uint, status string, updatedAt time.Time) error {
	return r.db.WithContext(ctx).
		Model(&Booking{}).
		Where("id = ?", id).
		Updates(map[string]any{
			"status":     status,
			"updated_at": updatedAt,
		}).Error
}

func (r *repository) GetBookedSlotIDs(ctx context.Context, technicianID uint, date string) ([]uint, error) {
	var slotIDs []uint
	err := r.db.WithContext(ctx).
		Model(&Booking{}).
		Where("technician_id = ? AND appointment_date = ? AND status NOT IN ?",
			technicianID, date, ExcludedFromAvailability,
		).
		Pluck("time_slot_id", &slotIDs).Error
	return slotIDs, err
}

func (r *repository) IsSlotBooked(ctx context.Context, technicianID uint, date string, slotID uint) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&Booking{}).
		Where("technician_id = ? AND appointment_date = ? AND time_slot_id = ? AND status NOT IN ?",
			technicianID, date, slotID, ExcludedFromAvailability,
		).
		Count(&count).Error
	return count > 0, err
}

func (r *repository) GetTechnicianServiceByTechnicianAndService(
	ctx context.Context,
	technicianID uint,
	serviceID uint,
) (*techService.TechnicianService, error) {
	var techSvc techService.TechnicianService
	err := r.db.WithContext(ctx).
		Preload("Service").
		Preload("Service.Category").
		Where("technician_id = ? AND service_id = ? AND is_active = ?",
			technicianID, serviceID, true).
		First(&techSvc).Error
	if err != nil {
		return nil, err
	}
	return &techSvc, nil
}

func (r *repository) GetCustomerAddress(ctx context.Context, addressID uint, customerID uint) (*address.CustomerAddress, error) {
	var addr address.CustomerAddress
	if err := r.db.WithContext(ctx).
		Preload("Province").
		Preload("District").
		Preload("SubDistrict").
		Where("id = ? AND customer_id = ?", addressID, customerID).
		First(&addr).Error; err != nil {
		return nil, err
	}
	return &addr, nil
}

func (r *repository) IsTechnicianServingProvince(ctx context.Context, technicianID uint, provinceID uint) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Table("technician_service_areas").
		Where("technician_id = ? AND province_id = ? AND is_active = ?", technicianID, provinceID, true).
		Count(&count).Error
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *repository) MarkAsPaid(ctx context.Context, bookingID uint) error {
	return r.db.WithContext(ctx).
		Model(&Booking{}).
		Where("id = ? AND status = ?", bookingID, BookingStatusWaitingPayment).
		Updates(map[string]any{
			"status":     BookingStatusCompleted,
			"updated_at": time.Now(),
		}).Error
}

func (r *repository) UpdateFinalPrice(ctx context.Context, bookingID uint, finalPrice float64) error {
	return r.db.WithContext(ctx).
		Model(&Booking{}).
		Where("id = ?", bookingID).
		Updates(map[string]any{
			"final_price": finalPrice,
			"updated_at":  time.Now(),
		}).Error
}

func (r *repository) UpdateLastRead(ctx context.Context, bookingID uint, role string, readAt time.Time) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		column := "last_read_by_customer"
		otherRole := "technician"
		if role == "technician" {
			column = "last_read_by_technician"
			otherRole = "customer"
		}

		if err := tx.Table("bookings").
			Where("id = ?", bookingID).
			Update(column, readAt).Error; err != nil {
			return err
		}

		if err := tx.Table("chat_messages").
			Where("booking_id = ? AND sender_role = ? AND is_read = ?",
				bookingID, otherRole, false).
			Update("is_read", true).Error; err != nil {
			return err
		}

		return nil
	})
}

func (r *repository) ListByCustomer(
	ctx context.Context,
	customerID uint,
	statuses []string,
	startDate string,
	endDate string,
	offset int,
	limit int,
) ([]Booking, int64, error) {
	q := r.db.WithContext(ctx).Model(&Booking{}).
		Where("customer_id = ?", customerID)

	if len(statuses) > 0 {
		q = q.Where("status IN ?", statuses)
	}
	if startDate != "" && endDate != "" {
		q = q.Where("appointment_date BETWEEN ? AND ?", startDate, endDate)
	} else if startDate != "" {
		q = q.Where("appointment_date >= ?", startDate)
	} else if endDate != "" {
		q = q.Where("appointment_date <= ?", endDate)
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var bookings []Booking
	err := q.
		Preload("Images").
		Preload("TimeSlot").
		Preload("Technician").
		Preload("TechnicianService").
		Preload("TechnicianService.Service").
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&bookings).Error
	if err != nil {
		return nil, 0, err
	}

	return bookings, total, nil
}

func (r *repository) ListByTechnician(
	ctx context.Context,
	technicianID uint,
	statuses []string,
	startDate string,
	endDate string,
	offset int,
	limit int,
) ([]Booking, int64, error) {
	q := r.db.WithContext(ctx).Model(&Booking{}).
		Where("technician_id = ?", technicianID)

	if len(statuses) > 0 {
		q = q.Where("status IN ?", statuses)
	}
	if startDate != "" && endDate != "" {
		q = q.Where("appointment_date BETWEEN ? AND ?", startDate, endDate)
	} else if startDate != "" {
		q = q.Where("appointment_date >= ?", startDate)
	} else if endDate != "" {
		q = q.Where("appointment_date <= ?", endDate)
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var bookings []Booking
	err := q.
		Preload("Customer", func(db *gorm.DB) *gorm.DB {
			return db.Select("id", "first_name", "last_name", "phone", "avatar_url")
		}).
		Preload("Images").
		Preload("TimeSlot").
		Preload("Technician").
		Preload("TechnicianService").
		Preload("TechnicianService.Service").
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&bookings).Error
	if err != nil {
		return nil, 0, err
	}

	return bookings, total, nil
}

func (r *repository) CreateReview(ctx context.Context, review *Review, images []ReviewImage) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(review).Error; err != nil {
			return err
		}
		if len(images) > 0 {
			for i := range images {
				images[i].ReviewID = review.ID
			}
			if err := tx.Create(&images).Error; err != nil {
				return err
			}
		}
		if err := tx.Model(&Booking{}).
			Where("id = ?", review.BookingID).
			Update("reviewed_at", review.CreatedAt).Error; err != nil {
			return err
		}
		return upsertServiceRatingTx(tx, ctx, review.ServiceID)
	})
}

func (r *repository) FindReviewByBookingID(ctx context.Context, bookingID uint) (*Review, error) {
	type rawRow struct {
		Review
		CustomerName   string `gorm:"column:customer_name"`
		CustomerAvatar string `gorm:"column:customer_avatar"`
		ServiceName    string `gorm:"column:service_name"`
		ServicePicture string `gorm:"column:service_picture"`
		CategoryID     uint   `gorm:"column:category_id"`
		CategoryName   string `gorm:"column:category_name"`
	}

	var raw rawRow
	err := r.db.WithContext(ctx).
		Table("reviews").
		Select(`
        reviews.*,
        CONCAT(customers.first_name, ' ', customers.last_name) AS customer_name,
        customers.avatar_url                                    AS customer_avatar,
        services.ser_name                                       AS service_name,
        JSON_UNQUOTE(JSON_EXTRACT(services.image_urls, '$[0]')) AS service_picture,
        services.category_id                                    AS category_id,
        service_categories.cat_name                            AS category_name
    `).
		Joins("JOIN customers ON customers.id = reviews.customer_id").
		Joins("JOIN bookings ON bookings.id = reviews.booking_id").
		Joins("JOIN technician_services ON technician_services.id = bookings.technician_service_id").
		Joins("JOIN services ON services.id = technician_services.service_id").
		Joins("JOIN service_categories ON service_categories.id = services.category_id").
		Where("reviews.booking_id = ?", bookingID).
		First(&raw).Error

	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	var imgs []ReviewImage
	if err := r.db.WithContext(ctx).
		Where("review_id = ?", raw.Review.ID).
		Find(&imgs).Error; err != nil {
		return nil, err
	}

	rev := raw.Review
	rev.Images = imgs
	rev.CustomerName = raw.CustomerName
	rev.CustomerAvatar = raw.CustomerAvatar
	rev.ServiceName = raw.ServiceName
	rev.ServicePicture = raw.ServicePicture
	rev.CategoryID = raw.CategoryID
	rev.CategoryName = raw.CategoryName
	return &rev, nil
}

func (r *repository) FindBookingForReview(ctx context.Context, bookingID uint, customerID uint) (*Booking, error) {
	var b Booking
	err := r.db.WithContext(ctx).
		Preload("TechnicianService").
		Where("id = ? AND customer_id = ?", bookingID, customerID).
		First(&b).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &b, nil
}

func (r *repository) UpsertServiceRating(ctx context.Context, serviceID uint) error {
	return upsertServiceRatingTx(r.db.WithContext(ctx), ctx, serviceID)
}

func upsertServiceRatingTx(db *gorm.DB, ctx context.Context, serviceID uint) error {
	return db.WithContext(ctx).Exec(`
		INSERT INTO service_rating_stats (service_id, avg_rating, total_reviews, updated_at)
		SELECT
			service_id,
			ROUND(AVG(rating), 2),
			COUNT(*),
			NOW()
		FROM reviews
		WHERE service_id = ?
		GROUP BY service_id
		ON DUPLICATE KEY UPDATE
			avg_rating    = VALUES(avg_rating),
			total_reviews = VALUES(total_reviews),
			updated_at    = NOW()
	`, serviceID).Error
}

func (r *repository) GetTechnicianReviewSummary(ctx context.Context, technicianID uint) (*ReviewSummary, error) {
	type row struct {
		Rating int8
		Count  int64
	}
	var rows []row

	err := r.db.WithContext(ctx).
		Table("reviews").
		Select("reviews.rating, COUNT(*) as count").
		Joins("JOIN bookings ON bookings.id = reviews.booking_id").
		Where("bookings.technician_id = ?", technicianID).
		Group("reviews.rating").
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}

	summary := &ReviewSummary{
		Breakdown: map[int]int64{1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
	}
	var totalScore int64
	for _, r := range rows {
		summary.Breakdown[int(r.Rating)] = r.Count
		summary.TotalReviews += r.Count
		totalScore += int64(r.Rating) * r.Count
	}
	if summary.TotalReviews > 0 {
		summary.AvgRating = math.Round(float64(totalScore)/float64(summary.TotalReviews)*10) / 10
	}
	return summary, nil
}

func (r *repository) ListReviewsByTechnician(
	ctx context.Context,
	technicianID uint,
	filter ReviewFilter,
	offset int,
	limit int,
) ([]ReviewWithDetail, int64, error) {

	baseQ := func(db *gorm.DB) *gorm.DB {
		q := db.WithContext(ctx).
			Table("reviews").
			Joins("JOIN bookings ON bookings.id = reviews.booking_id").
			Joins("JOIN technician_services ON technician_services.id = bookings.technician_service_id").
			Joins("JOIN services ON services.id = technician_services.service_id").
			Joins("JOIN service_categories ON service_categories.id = services.category_id").
			Where("bookings.technician_id = ?", technicianID)

		if filter.Rating != nil {
			q = q.Where("reviews.rating = ?", *filter.Rating)
		}
		if filter.HasImages != nil {
			if *filter.HasImages {
				q = q.Where("EXISTS (SELECT 1 FROM review_images WHERE review_images.review_id = reviews.id)")
			} else {
				q = q.Where("NOT EXISTS (SELECT 1 FROM review_images WHERE review_images.review_id = reviews.id)")
			}
		}
		if filter.ServiceType != nil {
			q = q.Where("services.category_id = ?", *filter.ServiceType)
		}
		return q
	}

	var total int64
	if err := baseQ(r.db).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	type rawRow struct {
		Review
		CustomerName   string   `gorm:"column:customer_name"`
		CustomerAvatar string   `gorm:"column:customer_avatar"`
		ServiceName    string   `gorm:"column:service_name"`
		ServicePicture string   `gorm:"column:service_picture"`
		CategoryID     uint     `gorm:"column:category_id"`
		CategoryName   string   `gorm:"column:category_name"`
		SvcPricingType string   `gorm:"column:svc_pricing_type"`
		SvcPriceFixed  *float64 `gorm:"column:svc_price_fixed"`
		SvcPriceMin    *float64 `gorm:"column:svc_price_min"`
		SvcPriceMax    *float64 `gorm:"column:svc_price_max"`
	}

	var raws []rawRow
	err := baseQ(r.db).
		Joins("JOIN customers ON customers.id = reviews.customer_id").
		Select(`
			reviews.*,
			CONCAT(customers.first_name, ' ', customers.last_name) AS customer_name,
			customers.avatar_url                                    AS customer_avatar,
			services.ser_name                                       AS service_name,
			JSON_UNQUOTE(JSON_EXTRACT(services.image_urls, '$[0]')) AS service_picture,
			services.category_id                                    AS category_id,
			service_categories.cat_name                            AS category_name,
			technician_services.pricing_type                       AS svc_pricing_type,
			technician_services.price_fixed                        AS svc_price_fixed,
			technician_services.price_min                          AS svc_price_min,
			technician_services.price_max                          AS svc_price_max
		`).
		Order("reviews.created_at DESC").
		Offset(offset).
		Limit(limit).
		Scan(&raws).Error
	if err != nil {
		return nil, 0, err
	}

	reviewIDs := make([]uint, len(raws))
	for i, rw := range raws {
		reviewIDs[i] = rw.Review.ID
	}

	imageMap := map[uint][]ReviewImage{}
	if len(reviewIDs) > 0 {
		var imgs []ReviewImage
		if err := r.db.WithContext(ctx).
			Where("review_id IN ?", reviewIDs).
			Find(&imgs).Error; err != nil {
			return nil, 0, err
		}
		for _, img := range imgs {
			imageMap[img.ReviewID] = append(imageMap[img.ReviewID], img)
		}
	}

	results := make([]ReviewWithDetail, len(raws))
	for i, rw := range raws {
		rw.Review.Images = imageMap[rw.Review.ID]
		results[i] = ReviewWithDetail{
			Review:         rw.Review,
			CustomerName:   rw.CustomerName,
			CustomerAvatar: rw.CustomerAvatar,
			ServiceName:    rw.ServiceName,
			ServicePrice:   formatServicePrice(rw.SvcPricingType, rw.SvcPriceFixed, rw.SvcPriceMin, rw.SvcPriceMax),
			ServicePicture: rw.ServicePicture,
			CategoryID:     rw.CategoryID,
			CategoryName:   rw.CategoryName,
		}
	}

	return results, total, nil
}

func formatServicePrice(pricingType string, fixed, min, max *float64) string {
	if pricingType == "FIXED" && fixed != nil {
		return fmt.Sprintf("฿%.0f", *fixed)
	}
	if min != nil && max != nil {
		return fmt.Sprintf("฿%.0f - ฿%.0f", *min, *max)
	}
	return ""
}
