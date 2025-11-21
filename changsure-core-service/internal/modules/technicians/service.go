package technicians

import (
	"context"
	"errors"
	"time"

	"changsure-core-service/internal/modules/badge"
	"changsure-core-service/internal/modules/provinces"
	addr "changsure-core-service/internal/modules/technician_addresses"
	tsvc "changsure-core-service/internal/modules/technician_services"

	"gorm.io/gorm"
)

type Service interface {
	UpsertProfile(ctx context.Context, techID uint, req TechnicianProfileReq) (uint, error)
	GetProfile(ctx context.Context, techID uint) (*TechnicianProfileRes, error)
	UpdateProvinces(ctx context.Context, techID uint, provinceIDs []uint) error
	AddService(ctx context.Context, techID uint, req AddTechServiceReq) (*AddedTechServiceResult, error)
	RemoveService(ctx context.Context, techID uint, req RemoveTechServiceReq) error
}

type service struct {
	db   *gorm.DB
	repo Repository
	area addr.Repository
}

type AddedTechServiceResult struct {
	TechnicianID uint             `json:"technician_id"`
	ProvinceID   uint             `json:"province_id"`
	Service      TechServiceBrief `json:"service"`
}

type TechServiceBrief struct {
	ID          uint     `json:"id"`
	Name        string   `json:"name"`
	PricingType string   `json:"pricing_type"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
}

func NewService(db *gorm.DB, r Repository, a addr.Repository) Service {
	return &service{db: db, repo: r, area: a}
}

func (s *service) UpsertProfile(ctx context.Context, techID uint, req TechnicianProfileReq) (uint, error) {
	if s.area == nil {
		return 0, errors.New("technicians.service: area repository not wired")
	}

	t := &Technician{ID: techID}

	if techID == 0 {
		if req.Email != nil && *req.Email != "" {
			if ex, err := s.repo.FindByEmail(ctx, *req.Email); err == nil {
				t = ex
			}
		} else if req.Phone != nil && *req.Phone != "" {
			if ex, err := s.repo.FindByPhone(ctx, *req.Phone); err == nil {
				t = ex
			}
		}
	} else {
		_ = s.db.WithContext(ctx).First(t, techID).Error
	}

	t.FirstName, t.LastName = req.FirstName, req.LastName
	t.Phone, t.Email, t.Bio, t.AvatarURL = req.Phone, req.Email, req.Bio, req.AvatarURL

	var id uint
	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var err error
		if t.ID == 0 {
			err = tx.Create(t).Error
		} else {
			err = tx.Save(t).Error
		}
		if err != nil {
			return err
		}
		id = t.ID

		if len(req.ProvinceIDs) > 0 {
			if err = s.area.ReplaceForTech(tx, t.ID, req.ProvinceIDs); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return 0, err
	}
	return id, nil
}

func (s *service) GetProfile(ctx context.Context, techID uint) (*TechnicianProfileRes, error) {
	if techID == 0 {
		return nil, errors.New("technician id is required")
	}

	var tech Technician
	if err := s.db.WithContext(ctx).
		Preload("ServiceAreas", "is_active = ?", true).
		Preload("ServiceAreas.Province").
		Preload("ServiceAreas.Services", "is_active = ?", true).
		Preload("ServiceAreas.Services.Service").
		Preload("Badges").
		Preload("Badges.Badge").
		First(&tech, techID).Error; err != nil {
		return nil, err
	}

	badgesRes := make([]badge.BadgeResponse, 0, len(tech.Badges))
	for _, tb := range tech.Badges {
		b := tb.Badge
		if b.ID == 0 {
			continue
		}

		badgesRes = append(badgesRes, badge.BadgeResponse{
			ID:          b.ID,
			Name:        b.Name,
			Description: b.Description,
			IconURL:     b.IconURL,
			Level:       b.Level,
			IsActive:    b.IsActive,
			CreatedAt:   b.CreatedAt.Unix(),
			UpdatedAt:   b.UpdatedAt.Unix(),
		})
	}
	provinceIDs := make([]uint, 0, len(tech.ServiceAreas))
	provincesRes := make([]provinces.ProvinceResponse, 0, len(tech.ServiceAreas))
	servicesRes := make([]TechServiceRes, 0, 8)

	for _, a := range tech.ServiceAreas {
		provinceIDs = append(provinceIDs, a.ProvinceID)
		p := a.Province
		provincesRes = append(provincesRes, provinces.ProvinceResponse{
			ID:        p.ID,
			NameTH:    p.NameTH,
			CreatedAt: p.CreatedAt.Format(time.RFC3339),
			UpdatedAt: p.UpdatedAt.Format(time.RFC3339),
		})

	}

	summaryMap := make(map[uint]string)
	for _, s := range servicesRes {
		summaryMap[s.ServiceID] = s.ServiceName
	}

	serviceSummary := make([]TechServiceSummary, 0, len(summaryMap))
	for id, name := range summaryMap {
		serviceSummary = append(serviceSummary, TechServiceSummary{
			ServiceID:   id,
			ServiceName: name,
		})
	}

	res := &TechnicianProfileRes{
		ID:             tech.ID,
		FirstName:      tech.FirstName,
		LastName:       tech.LastName,
		Bio:            tech.Bio,
		Phone:          tech.Phone,
		Email:          tech.Email,
		AvatarURL:      tech.AvatarURL,
		RatingAvg:      tech.RatingAvg,
		RatingCount:    tech.RatingCount,
		TotalJobs:      tech.TotalJobs,
		IsAvailable:    tech.IsAvailable,
		IsVerified:     tech.IsVerified,
		Provinces:      provincesRes,
		Services:       servicesRes,
		ServiceSummary: serviceSummary,
		Badges:         badgesRes,
	}
	return res, nil
}

func (s *service) UpdateProvinces(ctx context.Context, techID uint, provinceIDs []uint) error {
	if techID == 0 {
		return errors.New("technician id is required")
	}
	if s.area == nil {
		return errors.New("technicians.service: area repository not wired")
	}
	return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		return s.area.ReplaceForTech(tx, techID, provinceIDs)
	})
}

func (s *service) AddService(ctx context.Context, techID uint, req AddTechServiceReq) (*AddedTechServiceResult, error) {
	if techID == 0 {
		return nil, errors.New("technician id is required")
	}
	if s.area == nil {
		return nil, errors.New("technicians.service: area repository not wired")
	}

	var result AddedTechServiceResult

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {

		var area addr.TechnicianServiceArea
		if err := tx.
			Where("technician_id = ? AND province_id = ?", techID, req.ProvinceID).
			First(&area).Error; err != nil {

			if errors.Is(err, gorm.ErrRecordNotFound) {

				return errors.New("technician does not serve this province, please update provinces first")
			}
			return err
		}

		var existing tsvc.TechnicianService
		if err := tx.
			Where("technician_id = ? AND service_id = ?", techID, req.ServiceID).
			First(&existing).Error; err == nil {

			if err := tx.Model(&existing).Association("Service").Find(&existing.Service); err != nil {
				return err
			}

			result = AddedTechServiceResult{
				TechnicianID: techID,
				ProvinceID:   req.ProvinceID,
				Service: TechServiceBrief{
					ID:          existing.Service.ID,
					Name:        existing.Service.SerName,
					PricingType: existing.PricingType,
					PriceFixed:  existing.PriceFixed,
					PriceMin:    existing.PriceMin,
					PriceMax:    existing.PriceMax,
				},
			}
			return nil
		} else if !errors.Is(err, gorm.ErrRecordNotFound) {
			return err
		}

		ts := tsvc.TechnicianService{
			TechnicianID: techID,
			ServiceID:    req.ServiceID,
			PricingType:  req.PricingType,
			PriceFixed:   req.PriceFixed,
			PriceMin:     req.PriceMin,
			PriceMax:     req.PriceMax,
			IsActive:     true,
		}

		if err := tx.Create(&ts).Error; err != nil {
			return err
		}

		if err := tx.Model(&ts).Association("Service").Find(&ts.Service); err != nil {
			return err
		}

		result = AddedTechServiceResult{
			TechnicianID: techID,
			ProvinceID:   req.ProvinceID,
			Service: TechServiceBrief{
				ID:          ts.Service.ID,
				Name:        ts.Service.SerName,
				PricingType: ts.PricingType,
				PriceFixed:  ts.PriceFixed,
				PriceMin:    ts.PriceMin,
				PriceMax:    ts.PriceMax,
			},
		}
		return nil
	})

	if err != nil {
		return nil, err
	}

	return &result, nil
}

func (s *service) RemoveService(ctx context.Context, techID uint, req RemoveTechServiceReq) error {
	if techID == 0 {
		return errors.New("technician id is required")
	}
	if s.area == nil {
		return errors.New("technicians.service: area repository not wired")
	}
	if req.ProvinceID == 0 || req.ServiceID == 0 {
		return errors.New("province_id and service_id are required")
	}

	return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {

		var area addr.TechnicianServiceArea
		err := tx.
			Where("technician_id = ? AND province_id = ?", techID, req.ProvinceID).
			First(&area).Error

		if errors.Is(err, gorm.ErrRecordNotFound) {

			return nil
		}
		if err != nil {
			return err
		}

		if err := tx.Where(
			"technician_id = ? AND service_id = ?",
			techID, req.ServiceID,
		).Delete(&tsvc.TechnicianService{}).Error; err != nil {
			return err
		}

		return nil
	})
}
