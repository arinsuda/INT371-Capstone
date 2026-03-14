package technician

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"gorm.io/gorm"

	appErrors "changsure-core-service/internal/errors"
	docrepo "changsure-core-service/internal/modules/document"

	"changsure-core-service/internal/modules/badge"
	"changsure-core-service/internal/modules/province"

	tb "changsure-core-service/internal/modules/technician_badge"
	tsvc "changsure-core-service/internal/modules/technician_service"
	tsvca "changsure-core-service/internal/modules/technician_service_area"

	"changsure-core-service/pkg/storage"
)

type ctxKey string

const (
	ctxKeyRequestID ctxKey = "request_id"
	ctxKeyUserID    ctxKey = "user_id"
)

type Service interface {
	UpsertProfile(ctx context.Context, techID uint, req TechnicianProfileReq) (uint, error)
	GetProfile(ctx context.Context, techID uint) (*TechnicianProfileRes, error)
	UpdateProvinces(ctx context.Context, techID uint, provinceIDs []uint) error
	AddService(ctx context.Context, techID uint, req AddTechServiceReq) (*TechServiceMutationResult, error)
	UpdateService(ctx context.Context, techID uint, req UpdateTechServiceReq) (*TechServiceMutationResult, error)
	RemoveService(ctx context.Context, techID uint, req RemoveTechServiceReq) error
	UpdateAvatar(ctx context.Context, techID uint, avatarKey string) error
}

type service struct {
	db          *gorm.DB
	repo        Repository
	areaRepo    tsvca.Repository
	serviceRepo tsvc.Repository
	docRepo     docrepo.Repository
	storage     storage.Storage
	logger      *slog.Logger
}

func NewService(
	db *gorm.DB,
	repo Repository,
	areaRepo tsvca.Repository,
	svcRepo tsvc.Repository,
	docRepo docrepo.Repository,
	store storage.Storage,
	logger *slog.Logger,
) Service {
	if logger == nil {
		logger = slog.Default()
	}
	return &service{
		db:          db,
		repo:        repo,
		areaRepo:    areaRepo,
		serviceRepo: svcRepo,
		docRepo:     docRepo,
		storage:     store,
		logger:      logger.With("module", "technician"),
	}
}

func (s *service) log(ctx context.Context) *slog.Logger {
	l := s.logger
	if v, ok := ctx.Value(ctxKeyRequestID).(string); ok && v != "" {
		l = l.With("request_id", v)
	}
	if v, ok := ctx.Value(ctxKeyUserID).(uint); ok && v != 0 {
		l = l.With("caller_id", v)
	}
	return l
}

func (s *service) GetProfile(ctx context.Context, techID uint) (*TechnicianProfileRes, error) {
	tech, err := s.fetchWithAssociations(ctx, techID)
	if err != nil {
		s.log(ctx).Warn("get profile failed", "technician_id", techID, "error", err)
		return nil, err
	}
	return s.toProfileRes(ctx, tech), nil
}

func (s *service) UpsertProfile(ctx context.Context, techID uint, req TechnicianProfileReq) (uint, error) {
	log := s.log(ctx).With("technician_id", techID)

	var tech Technician
	if err := s.db.WithContext(ctx).First(&tech, techID).Error; err != nil {
		log.Warn("technician not found for profile upsert")
		return 0, appErrors.NewNotFound("technician not found")
	}

	if len(req.Services) > 0 {
		if err := validateServices(req.Services); err != nil {
			return 0, err
		}
	}

	applyProfileFields(&tech, req)

	id, err := tech.ID, s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(&tech).Error; err != nil {
			return fmt.Errorf("save technician: %w", err)
		}
		if len(req.ProvinceIDs) > 0 {
			if s.areaRepo == nil {
				return appErrors.NewBadRequest("area repository not initialized")
			}
			if err := s.areaRepo.ReplaceForTech(tx, tech.ID, req.ProvinceIDs); err != nil {
				return fmt.Errorf("update service areas: %w", err)
			}
		}
		if len(req.Services) > 0 {
			if s.serviceRepo == nil {
				return errors.New("service repository not initialized")
			}
			if err := s.serviceRepo.ReplaceAll(ctx, tx, tech.ID, req.Services); err != nil {
				return fmt.Errorf("update services: %w", err)
			}
		}
		return nil
	})

	if err != nil {
		log.Error("upsert profile failed", "error", err)
		return 0, err
	}

	log.Info("profile upserted",
		"provinces_updated", len(req.ProvinceIDs),
		"services_updated", len(req.Services),
	)
	return id, nil
}

func (s *service) UpdateProvinces(ctx context.Context, techID uint, provinceIDs []uint) error {
	log := s.log(ctx).With("technician_id", techID)

	if s.areaRepo == nil {
		return appErrors.NewBadRequest("area repository not initialized")

	}

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		return s.areaRepo.ReplaceForTech(tx, techID, provinceIDs)
	})
	if err != nil {
		log.Error("update provinces failed", "error", err)
		return err
	}

	log.Info("provinces updated", "province_count", len(provinceIDs))
	return nil
}

func (s *service) AddService(ctx context.Context, techID uint, req AddTechServiceReq) (*TechServiceMutationResult, error) {
	log := s.log(ctx).With("technician_id", techID, "service_id", req.ServiceID)

	var result TechServiceMutationResult

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var existing tsvc.TechnicianService
		err := tx.Where("technician_id = ? AND service_id = ?", techID, req.ServiceID).First(&existing).Error

		if err == nil {

			log.Info("add service skipped, already exists")
			_ = tx.Model(&existing).Association("Service").Find(&existing.Service)
			result = toMutationResult(techID, &existing)
			return nil
		}
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			return fmt.Errorf("check existing service: %w", err)
		}

		newSvc := tsvc.TechnicianService{
			TechnicianID: techID,
			ServiceID:    req.ServiceID,
			PricingType:  req.PricingType,
			PriceFixed:   req.PriceFixed,
			PriceMin:     req.PriceMin,
			PriceMax:     req.PriceMax,
			IsActive:     true,
		}
		if err := tx.Create(&newSvc).Error; err != nil {
			return fmt.Errorf("create technician service: %w", err)
		}
		_ = tx.Model(&newSvc).Association("Service").Find(&newSvc.Service)
		result = toMutationResult(techID, &newSvc)
		return nil
	})

	if err != nil {
		log.Error("add service failed", "error", err)
		return nil, err
	}

	log.Info("service added", "pricing_type", req.PricingType)
	return &result, nil
}

func (s *service) UpdateService(ctx context.Context, techID uint, req UpdateTechServiceReq) (*TechServiceMutationResult, error) {
	if req.ServiceID == 0 {
		return nil, appErrors.NewBadRequest("service_id is required")
	}

	log := s.log(ctx).With("technician_id", techID, "service_id", req.ServiceID)

	var result TechServiceMutationResult

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var existing tsvc.TechnicianService
		if err := tx.Where("technician_id = ? AND service_id = ?", techID, req.ServiceID).
			First(&existing).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return appErrors.NewNotFound("service not found for this technician")
			}
			return fmt.Errorf("find service: %w", err)
		}

		updates := map[string]any{}
		if req.PricingType != "" {
			updates["pricing_type"] = req.PricingType
		}
		if req.PriceFixed != nil {
			updates["price_fixed"] = req.PriceFixed
		}
		if req.PriceMin != nil {
			updates["price_min"] = req.PriceMin
		}
		if req.PriceMax != nil {
			updates["price_max"] = req.PriceMax
		}

		if len(updates) > 0 {
			if err := tx.Model(&existing).Updates(updates).Error; err != nil {
				return fmt.Errorf("update service: %w", err)
			}
		}

		_ = tx.Model(&existing).Association("Service").Find(&existing.Service)
		result = toMutationResult(techID, &existing)
		return nil
	})

	if err != nil {
		log.Error("update service failed", "error", err)
		return nil, err
	}

	log.Info("service updated")
	return &result, nil
}

func (s *service) RemoveService(ctx context.Context, techID uint, req RemoveTechServiceReq) error {
	if req.ServiceID == 0 {
		return appErrors.NewBadRequest("service_id is required")
	}

	log := s.log(ctx).With("technician_id", techID, "service_id", req.ServiceID)

	tx := s.db.WithContext(ctx).
		Where("technician_id = ? AND service_id = ?", techID, req.ServiceID).
		Delete(&tsvc.TechnicianService{})

	if tx.Error != nil {
		log.Error("remove service failed", "error", tx.Error)
		return fmt.Errorf("delete service: %w", tx.Error)
	}

	if tx.RowsAffected == 0 {
		log.Warn("remove service skipped, not found")
		return appErrors.NewNotFound("service not found for this technician")
	}

	log.Info("service removed")
	return nil
}

func (s *service) UpdateAvatar(ctx context.Context, techID uint, avatarKey string) error {
	log := s.log(ctx).With("technician_id", techID)

	err := s.db.WithContext(ctx).
		Model(&Technician{}).
		Where("id = ?", techID).
		Update("avatar_url", avatarKey).Error

	if err != nil {
		log.Error("update avatar failed", "error", err)
		return err
	}

	log.Info("avatar updated", "key", avatarKey)
	return nil
}

func (s *service) fetchWithAssociations(ctx context.Context, techID uint) (*Technician, error) {
	var tech Technician
	err := s.db.WithContext(ctx).
		Preload("ServiceAreas", "is_active = ?", true).
		Preload("ServiceAreas.Province").
		Preload("Services", "is_active = ?", true).
		Preload("Services.Service").
		Preload("Services.Service.Category").
		Preload("Badges").
		Preload("Badges.Badge").
		First(&tech, techID).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, appErrors.NewNotFound("technician not found")
		}
		return nil, fmt.Errorf("fetch technician: %w", err)
	}
	return &tech, nil
}

func (s *service) toProfileRes(ctx context.Context, tech *Technician) *TechnicianProfileRes {
	termsAccepted, _ := s.docRepo.HasAccepted(ctx, tech.ID, "technician", "terms-of-service")
	privacyAccepted, _ := s.docRepo.HasAccepted(ctx, tech.ID, "technician", "privacy-policy")

	return &TechnicianProfileRes{
		ID:              tech.ID,
		FirstName:       tech.FirstName,
		LastName:        tech.LastName,
		Bio:             tech.Bio,
		Phone:           tech.Phone,
		Email:           tech.Email,
		AvatarURL:       s.presignURL(ctx, tech.AvatarURL),
		RatingAvg:       tech.RatingAvg,
		RatingCount:     tech.RatingCount,
		TotalJobs:       tech.TotalJobs,
		IsAvailable:     tech.IsAvailable,
		IsVerified:      tech.IsVerified,
		TermsAccepted:   termsAccepted,
		PrivacyAccepted: privacyAccepted,
		Provinces:       s.toProvincesRes(tech.ServiceAreas),
		Services:        s.toServicesRes(tech.Services),
		ServiceSummary:  s.toServiceSummary(tech.Services),
		Badges:          s.toBadgesRes(ctx, tech.Badges),
	}
}

func (s *service) toProvincesRes(areas []tsvca.TechnicianServiceArea) []province.ProvinceResponse {
	res := make([]province.ProvinceResponse, 0, len(areas))
	for _, a := range areas {
		res = append(res, province.ProvinceResponse{
			ID:        a.Province.ID,
			NameTH:    a.Province.NameTH,
			CreatedAt: a.Province.CreatedAt.Format(time.RFC3339),
			UpdatedAt: a.Province.UpdatedAt.Format(time.RFC3339),
		})
	}
	return res
}

func (s *service) toServicesRes(services []tsvc.TechnicianService) []TechServiceRes {
	res := make([]TechServiceRes, 0, len(services))
	for _, ts := range services {
		if ts.Service.ID == 0 {
			continue
		}
		var catID *uint
		var catName *string
		if ts.Service.Category != nil && ts.Service.Category.ID != 0 {
			catID = &ts.Service.Category.ID
			catName = &ts.Service.Category.CatName
		}
		res = append(res, TechServiceRes{
			ServiceID:   ts.Service.ID,
			ServiceName: ts.Service.SerName,
			CategoryID:  catID,
			Category:    catName,
			PricingType: ts.PricingType,
			PriceFixed:  ts.PriceFixed,
			PriceMin:    ts.PriceMin,
			PriceMax:    ts.PriceMax,
		})
	}
	return res
}

func (s *service) toServiceSummary(services []tsvc.TechnicianService) []TechServiceSummary {
	m := make(map[uint]*TechServiceSummary)
	for _, ts := range services {
		svc := ts.Service
		if svc.ID == 0 {
			continue
		}
		catID := svc.CategoryID
		catName := "Unknown"
		if svc.Category != nil {
			catName = svc.Category.CatName
		}
		if m[catID] == nil {
			m[catID] = &TechServiceSummary{
				ServiceCategoryID:   catID,
				ServiceCategoryName: catName,
				Services:            []TechServiceSummaryItem{},
			}
		}
		m[catID].Services = append(m[catID].Services, TechServiceSummaryItem{
			ServiceID:   svc.ID,
			ServiceName: svc.SerName,
		})
	}
	res := make([]TechServiceSummary, 0, len(m))
	for _, v := range m {
		res = append(res, *v)
	}
	return res
}

func (s *service) toBadgesRes(ctx context.Context, techBadges []tb.TechnicianBadge) []badge.BadgeResponse {
	res := make([]badge.BadgeResponse, 0, len(techBadges))
	for _, row := range techBadges {
		b := row.Badge
		if b.ID == 0 {
			continue
		}
		iconURL := s.presignURLStr(ctx, b.IconURL)
		res = append(res, badge.BadgeResponse{
			ID:          b.ID,
			Name:        b.Name,
			Description: b.Description,
			IconURL:     iconURL,
			Level:       b.Level,
			IsActive:    b.IsActive,
			CreatedAt:   b.CreatedAt.Unix(),
			UpdatedAt:   b.UpdatedAt.Unix(),
		})
	}
	return res
}

const presignTTL = time.Hour

func (s *service) presignURL(ctx context.Context, key *string) *string {
	if key == nil || *key == "" {
		empty := ""
		return &empty
	}
	signed := s.presignURLStr(ctx, *key)
	return &signed
}

func (s *service) presignURLStr(ctx context.Context, key string) string {
	if key == "" || s.storage == nil {
		return key
	}
	signed, err := s.storage.PresignGet(ctx, key, presignTTL, false)
	if err != nil {
		s.log(ctx).Warn("presign failed, falling back to raw key", "key", key, "error", err)
		return key
	}
	return signed
}

func applyProfileFields(tech *Technician, req TechnicianProfileReq) {
	if req.FirstName != "" {
		tech.FirstName = req.FirstName
	}
	if req.LastName != "" {
		tech.LastName = req.LastName
	}
	if req.Phone != nil {
		tech.Phone = req.Phone
	}
	if req.Email != nil {
		tech.Email = req.Email
	}
	if req.Bio != nil {
		tech.Bio = req.Bio
	}
	if req.AvatarURL != nil && *req.AvatarURL != "" {
		tech.AvatarURL = req.AvatarURL
	}
}

func toMutationResult(techID uint, ts *tsvc.TechnicianService) TechServiceMutationResult {
	return TechServiceMutationResult{
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
}

func validateServices(items []tsvc.ServicePatchItem) error {
	for _, s := range items {

		if s.ServiceID == 0 {
			return fmt.Errorf("service_id required")
		}

		switch s.PricingType {

		case "FIXED":
			if s.PriceFixed == nil {
				return fmt.Errorf("price_fixed required for service %d", s.ServiceID)
			}

		case "RANGE":
			if s.PriceMin == nil || s.PriceMax == nil {
				return fmt.Errorf("price_min and price_max required for service %d", s.ServiceID)
			}

		default:
			return fmt.Errorf("invalid pricing_type for service %d", s.ServiceID)
		}
	}
	return nil
}
