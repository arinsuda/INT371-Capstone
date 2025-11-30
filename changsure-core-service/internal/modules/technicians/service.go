package technicians

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"gorm.io/gorm"

	"changsure-core-service/internal/modules/badge"
	"changsure-core-service/internal/modules/provinces"

	tb "changsure-core-service/internal/modules/technician_badges"
	addr "changsure-core-service/internal/modules/technician_service_areas"
	tsvca "changsure-core-service/internal/modules/technician_service_areas"
	tsvc "changsure-core-service/internal/modules/technician_services"
	"changsure-core-service/pkg/storage"
)

// Common errors
var (
	ErrUnauthorized      = errors.New("unauthorized: technician id missing from auth")
	ErrAreaRepoNotWired  = errors.New("area repository not initialized")
	ErrServiceIDRequired = errors.New("service_id is required")
)

// Service defines the interface for technician-related operations
type Service interface {
	UpsertProfile(ctx context.Context, techID uint, req TechnicianProfileReq) (uint, error)
	GetProfile(ctx context.Context, techID uint) (*TechnicianProfileRes, error)
	UpdateProvinces(ctx context.Context, techID uint, provinceIDs []uint) error
	AddService(ctx context.Context, techID uint, req AddTechServiceReq) (*AddedTechServiceResult, error)
	RemoveService(ctx context.Context, techID uint, req RemoveTechServiceReq) error
	UpdateAvatar(ctx context.Context, techID uint, avatarPath string) error
}

type service struct {
	db       *gorm.DB
	repo     Repository
	areaRepo addr.Repository
	storage  *storage.MinioStorage
}

// AddedTechServiceResult represents the result of adding a service to a technician
type AddedTechServiceResult struct {
	TechnicianID uint             `json:"technician_id"`
	Service      TechServiceBrief `json:"service"`
}

// TechServiceBrief contains brief information about a technician service
type TechServiceBrief struct {
	ID          uint     `json:"id"`
	Name        string   `json:"name"`
	PricingType string   `json:"pricing_type"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
}

// NewService creates a new technician service instance
func NewService(db *gorm.DB, repo Repository, areaRepo addr.Repository) Service {
	return &service{
		db:       db,
		repo:     repo,
		areaRepo: areaRepo,
		storage:  storage.GlobalMinio,
	}
}

// UpsertProfile creates or updates a technician profile
func (s *service) UpsertProfile(ctx context.Context, techID uint, req TechnicianProfileReq) (uint, error) {
	if err := s.validateTechID(techID); err != nil {
		return 0, err
	}

	if err := s.validateAreaRepo(); err != nil {
		return 0, err
	}

	req.AvatarURL = s.normalizeAvatarURL(req.AvatarURL)

	var tech Technician
	if err := s.db.WithContext(ctx).First(&tech, techID).Error; err != nil {
		return 0, fmt.Errorf("failed to find technician: %w", err)
	}

	s.updateTechnicianFields(&tech, req)

	if err := s.upsertProfileTransaction(ctx, &tech, req.ProvinceIDs); err != nil {
		return 0, err
	}

	return tech.ID, nil
}

// GetProfile retrieves a technician's complete profile
func (s *service) GetProfile(ctx context.Context, techID uint) (*TechnicianProfileRes, error) {
	if err := s.validateTechID(techID); err != nil {
		return nil, err
	}

	tech, err := s.fetchTechnicianWithAssociations(ctx, techID)
	if err != nil {
		return nil, err
	}

	return s.buildProfileResponse(tech), nil
}

// UpdateProvinces updates the service areas (provinces) for a technician
func (s *service) UpdateProvinces(ctx context.Context, techID uint, provinceIDs []uint) error {
	if err := s.validateTechID(techID); err != nil {
		return err
	}

	if err := s.validateAreaRepo(); err != nil {
		return err
	}

	return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		return s.areaRepo.ReplaceForTech(tx, techID, provinceIDs)
	})
}

// AddService adds a service to a technician's service list
func (s *service) AddService(ctx context.Context, techID uint, req AddTechServiceReq) (*AddedTechServiceResult, error) {
	if err := s.validateTechID(techID); err != nil {
		return nil, err
	}

	var result AddedTechServiceResult

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// Check if service already exists
		existing, err := s.findExistingService(tx, techID, req.ServiceID)
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			return fmt.Errorf("failed to check existing service: %w", err)
		}

		if existing != nil {
			result = s.buildServiceResult(techID, existing)
			return nil
		}

		// Create new service
		newService, err := s.createTechnicianService(tx, techID, req)
		if err != nil {
			return err
		}

		result = s.buildServiceResult(techID, newService)
		return nil
	})

	if err != nil {
		return nil, err
	}

	return &result, nil
}

// RemoveService removes a service from a technician's service list
func (s *service) RemoveService(ctx context.Context, techID uint, req RemoveTechServiceReq) error {
	if err := s.validateTechID(techID); err != nil {
		return err
	}

	if req.ServiceID == 0 {
		return ErrServiceIDRequired
	}

	return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		result := tx.Where("technician_id = ? AND service_id = ?", techID, req.ServiceID).
			Delete(&tsvc.TechnicianService{})

		if result.Error != nil {
			return fmt.Errorf("failed to remove service: %w", result.Error)
		}

		return nil
	})
}

// UpdateAvatar updates the avatar URL for a technician
func (s *service) UpdateAvatar(ctx context.Context, techID uint, avatarPath string) error {
	if err := s.validateTechID(techID); err != nil {
		return err
	}

	result := s.db.WithContext(ctx).
		Model(&Technician{}).
		Where("id = ?", techID).
		Update("avatar_url", avatarPath)

	if result.Error != nil {
		return fmt.Errorf("failed to update avatar: %w", result.Error)
	}

	return nil
}

// Private helper methods

func (s *service) validateTechID(techID uint) error {
	if techID == 0 {
		return ErrUnauthorized
	}
	return nil
}

func (s *service) validateAreaRepo() error {
	if s.areaRepo == nil {
		return ErrAreaRepoNotWired
	}
	return nil
}

func (s *service) normalizeAvatarURL(url *string) *string {
	if url == nil || *url == "" {
		return url
	}
	if s.storage == nil {
		return url
	}

	cfg := s.storage.Config()
	if cfg == nil || cfg.PublicBaseURL == "" {
		return url
	}

	baseURL := cfg.PublicBaseURL
	if !strings.HasPrefix(*url, baseURL) {
		return url
	}

	trimmed := strings.TrimPrefix(*url, baseURL+"/")
	return &trimmed
}

func (s *service) updateTechnicianFields(tech *Technician, req TechnicianProfileReq) {
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
	if req.AvatarURL != nil {
		tech.AvatarURL = req.AvatarURL
	}
}

func (s *service) upsertProfileTransaction(ctx context.Context, tech *Technician, provinceIDs []uint) error {
	return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(tech).Error; err != nil {
			return fmt.Errorf("failed to save technician: %w", err)
		}

		if len(provinceIDs) > 0 {
			if err := s.areaRepo.ReplaceForTech(tx, tech.ID, provinceIDs); err != nil {
				return fmt.Errorf("failed to update service areas: %w", err)
			}
		}

		return nil
	})
}

func (s *service) fetchTechnicianWithAssociations(ctx context.Context, techID uint) (*Technician, error) {
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
		return nil, fmt.Errorf("failed to fetch technician profile: %w", err)
	}

	return &tech, nil
}

func (s *service) buildProfileResponse(tech *Technician) *TechnicianProfileRes {
	return &TechnicianProfileRes{
		ID:             tech.ID,
		FirstName:      tech.FirstName,
		LastName:       tech.LastName,
		Bio:            tech.Bio,
		Phone:          tech.Phone,
		Email:          tech.Email,
		AvatarURL:      s.buildAvatarURL(tech.AvatarURL),
		RatingAvg:      tech.RatingAvg,
		RatingCount:    tech.RatingCount,
		TotalJobs:      tech.TotalJobs,
		IsAvailable:    tech.IsAvailable,
		IsVerified:     tech.IsVerified,
		Provinces:      s.buildProvincesResponse(tech.ServiceAreas),
		Services:       s.buildServicesResponse(tech.Services),
		ServiceSummary: s.buildServiceSummary(tech.Services),
		Badges:         s.buildBadgesResponse(tech.Badges),
	}
}

func (s *service) buildAvatarURL(avatarURL *string) *string {
	if avatarURL == nil || *avatarURL == "" || s.storage == nil {
		emptyStr := ""
		return &emptyStr
	}

	publicURL := s.storage.PublicURL(*avatarURL)
	return &publicURL
}

func (s *service) buildBadgesResponse(techBadges []tb.TechnicianBadge) []badge.BadgeResponse {
	result := make([]badge.BadgeResponse, 0, len(techBadges))

	for _, tb := range techBadges {
		b := tb.Badge
		if b.ID == 0 {
			continue
		}

		iconURL := ""
		if b.IconURL != "" && s.storage != nil {
			iconURL = s.storage.PublicURL(b.IconURL)
		}

		result = append(result, badge.BadgeResponse{
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

	return result
}

func (s *service) buildProvincesResponse(serviceAreas []tsvca.TechnicianServiceArea) []provinces.ProvinceResponse {
	result := make([]provinces.ProvinceResponse, 0, len(serviceAreas))

	for _, area := range serviceAreas {
		p := area.Province
		result = append(result, provinces.ProvinceResponse{
			ID:        p.ID,
			NameTH:    p.NameTH,
			CreatedAt: p.CreatedAt.Format(time.RFC3339),
			UpdatedAt: p.UpdatedAt.Format(time.RFC3339),
		})
	}

	return result
}

func (s *service) buildServicesResponse(techServices []tsvc.TechnicianService) []TechServiceRes {
	result := make([]TechServiceRes, 0, len(techServices))

	for _, ts := range techServices {
		if ts.Service.ID == 0 {
			continue
		}

		result = append(result, TechServiceRes{
			ServiceID:   ts.Service.ID,
			ServiceName: ts.Service.SerName,
			PricingType: ts.PricingType,
			PriceFixed:  ts.PriceFixed,
			PriceMin:    ts.PriceMin,
			PriceMax:    ts.PriceMax,
		})
	}

	return result
}

func (s *service) buildServiceSummary(techServices []tsvc.TechnicianService) []TechServiceSummary {
	summaryMap := make(map[uint]*TechServiceSummary)

	for _, ts := range techServices {
		svc := ts.Service
		if svc.ID == 0 {
			continue
		}

		catID := svc.CategoryID
		catName := "Unknown"
		if svc.Category != nil {
			catName = svc.Category.CatName
		}

		if summaryMap[catID] == nil {
			summaryMap[catID] = &TechServiceSummary{
				ServiceCategoryID:   catID,
				ServiceCategoryName: catName,
				Services:            []TechServiceSummaryItem{},
			}
		}

		summaryMap[catID].Services = append(
			summaryMap[catID].Services,
			TechServiceSummaryItem{
				ServiceID:   svc.ID,
				ServiceName: svc.SerName,
			},
		)
	}

	result := make([]TechServiceSummary, 0, len(summaryMap))
	for _, summary := range summaryMap {
		result = append(result, *summary)
	}

	return result
}

func (s *service) findExistingService(tx *gorm.DB, techID, serviceID uint) (*tsvc.TechnicianService, error) {
	var existing tsvc.TechnicianService
	err := tx.
		Where("technician_id = ? AND service_id = ?", techID, serviceID).
		First(&existing).Error

	if err != nil {
		return nil, err
	}

	if err := tx.Model(&existing).Association("Service").Find(&existing.Service); err != nil {
		return nil, fmt.Errorf("failed to load service association: %w", err)
	}

	return &existing, nil
}

func (s *service) createTechnicianService(tx *gorm.DB, techID uint, req AddTechServiceReq) (*tsvc.TechnicianService, error) {
	techService := tsvc.TechnicianService{
		TechnicianID: techID,
		ServiceID:    req.ServiceID,
		PricingType:  req.PricingType,
		PriceFixed:   req.PriceFixed,
		PriceMin:     req.PriceMin,
		PriceMax:     req.PriceMax,
		IsActive:     true,
	}

	if err := tx.Create(&techService).Error; err != nil {
		return nil, fmt.Errorf("failed to create technician service: %w", err)
	}

	if err := tx.Model(&techService).Association("Service").Find(&techService.Service); err != nil {
		return nil, fmt.Errorf("failed to load service association: %w", err)
	}

	return &techService, nil
}

func (s *service) buildServiceResult(techID uint, ts *tsvc.TechnicianService) AddedTechServiceResult {
	return AddedTechServiceResult{
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
