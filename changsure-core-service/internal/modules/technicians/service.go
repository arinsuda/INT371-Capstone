package technicians

import (
	"context"
	"errors"
	"time"

	"changsure-core-service/internal/modules/badge"
	"changsure-core-service/internal/modules/provinces"
	addr "changsure-core-service/internal/modules/technician_service_areas"
	tsvc "changsure-core-service/internal/modules/technician_services"

	"gorm.io/gorm"

	"changsure-core-service/pkg/storage"
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
	if techID == 0 {
		return 0, errors.New("unauthorized: technician id missing from auth")
	}
	if s.area == nil {
		return 0, errors.New("technicians.service: area repository not wired")
	}

	var t Technician
	if err := s.db.WithContext(ctx).First(&t, techID).Error; err != nil {
		return 0, err
	}

	t.FirstName = req.FirstName
	t.LastName = req.LastName
	t.Phone = req.Phone
	t.Email = req.Email
	t.Bio = req.Bio
	t.AvatarURL = req.AvatarURL

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(&t).Error; err != nil {
			return err
		}

		if len(req.ProvinceIDs) > 0 {
			if err := s.area.ReplaceForTech(tx, t.ID, req.ProvinceIDs); err != nil {
				return err
			}
		}

		return nil
	})
	if err != nil {
		return 0, err
	}

	return t.ID, nil
}

func (s *service) GetProfile(ctx context.Context, techID uint) (*TechnicianProfileRes, error) {
	if techID == 0 {
		return nil, errors.New("unauthorized: technician id missing from auth")
	}

	var tech Technician
	if err := s.db.WithContext(ctx).
		Preload("ServiceAreas", "is_active = ?", true).
		Preload("ServiceAreas.Province").
		Preload("Services", "is_active = ?", true).
		Preload("Services.Service").
		Preload("Services.Service.Category").
		Preload("Badges").
		Preload("Badges.Badge").
		First(&tech, techID).Error; err != nil {
		return nil, err
	}

	var avatar string
	if tech.AvatarURL != nil && *tech.AvatarURL != "" {
		if storage.GlobalMinio != nil {

			avatar = storage.GlobalMinio.PublicURL(*tech.AvatarURL)

			if avatar == "" {
				if url, err := storage.GlobalMinio.PresignGet(
					context.Background(),
					*tech.AvatarURL,
					time.Hour,
					false,
				); err == nil {
					avatar = url
				}
			}
		}
	}

	badgesRes := make([]badge.BadgeResponse, 0, len(tech.Badges))
	for _, tb := range tech.Badges {
		b := tb.Badge
		if b.ID == 0 {
			continue
		}

		icon := ""
		if b.IconURL != "" && storage.GlobalMinio != nil {
			icon = storage.GlobalMinio.PublicURL(b.IconURL)
			if icon == "" {
				if u, err := storage.GlobalMinio.PresignGet(context.Background(), b.IconURL, time.Hour, false); err == nil {
					icon = u
				}
			}
		}

		badgesRes = append(badgesRes, badge.BadgeResponse{
			ID:          b.ID,
			Name:        b.Name,
			Description: b.Description,
			IconURL:     icon,
			Level:       b.Level,
			IsActive:    b.IsActive,
			CreatedAt:   b.CreatedAt.Unix(),
			UpdatedAt:   b.UpdatedAt.Unix(),
		})
	}

	provincesRes := make([]provinces.ProvinceResponse, 0, len(tech.ServiceAreas))
	for _, a := range tech.ServiceAreas {
		p := a.Province
		provincesRes = append(provincesRes, provinces.ProvinceResponse{
			ID:        p.ID,
			NameTH:    p.NameTH,
			CreatedAt: p.CreatedAt.Format(time.RFC3339),
			UpdatedAt: p.UpdatedAt.Format(time.RFC3339),
		})
	}

	servicesRes := make([]TechServiceRes, 0, len(tech.Services))
	for _, ts := range tech.Services {
		if ts.Service.ID == 0 {
			continue
		}
		servicesRes = append(servicesRes, TechServiceRes{
			ServiceID:   ts.Service.ID,
			ServiceName: ts.Service.SerName,
			PricingType: ts.PricingType,
			PriceFixed:  ts.PriceFixed,
			PriceMin:    ts.PriceMin,
			PriceMax:    ts.PriceMax,
		})
	}

	summaryGroups := make(map[uint]*TechServiceSummary)
	for _, ts := range tech.Services {
		svc := ts.Service
		if svc.ID == 0 {
			continue
		}

		catID := svc.CategoryID
		catName := "Unknown"
		if svc.Category != nil {
			catName = svc.Category.CatName
		}

		if summaryGroups[catID] == nil {
			summaryGroups[catID] = &TechServiceSummary{
				ServiceCategoryID:   catID,
				ServiceCategoryName: catName,
				Services:            []TechServiceSummaryItem{},
			}
		}

		summaryGroups[catID].Services = append(
			summaryGroups[catID].Services,
			TechServiceSummaryItem{
				ServiceID:   svc.ID,
				ServiceName: svc.SerName,
			},
		)
	}

	serviceSummary := make([]TechServiceSummary, 0, len(summaryGroups))
	for _, v := range summaryGroups {
		serviceSummary = append(serviceSummary, *v)
	}

	res := &TechnicianProfileRes{
		ID:             tech.ID,
		FirstName:      tech.FirstName,
		LastName:       tech.LastName,
		Bio:            tech.Bio,
		Phone:          tech.Phone,
		Email:          tech.Email,
		AvatarURL:      &avatar,
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
		return errors.New("unauthorized: technician id missing from auth")
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
		return nil, errors.New("unauthorized: technician id missing from auth")
	}

	var result AddedTechServiceResult

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {

		var existing tsvc.TechnicianService
		if err := tx.
			Where("technician_id = ? AND service_id = ?", techID, req.ServiceID).
			First(&existing).Error; err == nil {

			if err := tx.Model(&existing).Association("Service").Find(&existing.Service); err != nil {
				return err
			}

			result = AddedTechServiceResult{
				TechnicianID: techID,
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
		return errors.New("unauthorized: technician id missing from auth")
	}
	if req.ServiceID == 0 {
		return errors.New("service_id is required")
	}

	return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		return tx.Where("technician_id = ? AND service_id = ?", techID, req.ServiceID).
			Delete(&tsvc.TechnicianService{}).Error
	})
}
