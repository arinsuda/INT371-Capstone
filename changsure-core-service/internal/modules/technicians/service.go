package technicians

import (
	"context"
	"errors"
	"time"

	"changsure-core-service/internal/modules/badge"
	"changsure-core-service/internal/modules/provinces"
	addr "changsure-core-service/internal/modules/technician_addresses"

	"gorm.io/gorm"
)

type Service interface {
	UpsertProfile(ctx context.Context, techID uint, req TechnicianProfileReq) (uint, error)
	GetProfile(ctx context.Context, techID uint) (*TechnicianProfileRes, error)
	UpdateProvinces(ctx context.Context, techID uint, provinceIDs []uint) error
}

type service struct {
	db   *gorm.DB
	repo Repository
	area addr.Repository
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
			if ex, err := s.repo.FindByEmail(*req.Email); err == nil {
				t = ex
			}
		} else if req.Phone != nil && *req.Phone != "" {
			if ex, err := s.repo.FindByPhone(*req.Phone); err == nil {
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

		for _, ts := range a.Services {
			if !ts.IsActive {
				continue
			}
			var catID *uint
			var catName *string
			if ts.Service.Category != nil {
				cid := ts.Service.Category.ID
				cnm := ts.Service.Category.CatName
				catID = &cid
				catName = &cnm
			}

			servicesRes = append(servicesRes, TechServiceRes{
				AreaID:      a.ID,
				ProvinceID:  a.ProvinceID,
				ServiceID:   ts.ServiceID,
				ServiceName: ts.Service.SerName,
				CategoryID:  catID,
				Category:    catName,
				PricingType: ts.PricingType,
				PriceFixed:  ts.PriceFixed,
				PriceMin:    ts.PriceMin,
				PriceMax:    ts.PriceMax,
			})
		}
	}

	res := &TechnicianProfileRes{
		ID:          tech.ID,
		FirstName:   tech.FirstName,
		LastName:    tech.LastName,
		Bio:         tech.Bio,
		Phone:       tech.Phone,
		Email:       tech.Email,
		AvatarURL:   tech.AvatarURL,
		RatingAvg:   tech.RatingAvg,
		RatingCount: tech.RatingCount,
		TotalJobs:   tech.TotalJobs,
		IsAvailable: tech.IsAvailable,
		IsVerified:  tech.IsVerified,
		Provinces:   provincesRes,
		Services:    servicesRes,
		Badges:      badgesRes, // 👈 ใช้ badgesRes โดยตรง
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
