package database

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	"gorm.io/gorm"

	badge "changsure-core-service/internal/modules/badge"
	"changsure-core-service/internal/modules/province"
	"changsure-core-service/internal/modules/service"
	servicecategory "changsure-core-service/internal/modules/service_category"
	"changsure-core-service/internal/modules/technician"
	technicianaddress "changsure-core-service/internal/modules/technician_address"
	technicianbadge "changsure-core-service/internal/modules/technician_badge"
	technicianservice "changsure-core-service/internal/modules/technician_service"
	technicianservicearea "changsure-core-service/internal/modules/technician_service_area"
)

const (
	seedsDir       = "./seeds"
	provincesFile  = seedsDir + "/provinces/province.json"
	categoriesFile = seedsDir + "/categories/category.json"
	servicesFile   = seedsDir + "/services/service.json"
	badgesFile     = seedsDir + "/badges/badge.json"

	techniciansFile            = seedsDir + "/technicians/technician.json"
	technicianAddressesFile    = seedsDir + "/technicians/technician_address.json"
	technicianBadgesFile       = seedsDir + "/technicians/technician_badge.json"
	technicianServicesFile     = seedsDir + "/technicians/technician_service.json"
	technicianServiceAreasFile = seedsDir + "/technicians/technician_service_area.json"
)

type Seeder struct {
	db *gorm.DB
}

func NewSeeder(db *gorm.DB) *Seeder {
	return &Seeder{db: db}
}

func (d *Database) Seed() error {
	log.Println("🌱 Starting Database Seeding Process...")
	log.Println("==================================================")

	seeder := NewSeeder(d.DB)

	steps := []struct {
		Name string
		Run  func() error
	}{
		{"Provinces", seeder.seedProvinces},
		{"Service Categories", seeder.seedServiceCategories},
		{"Services", seeder.seedServices},
		{"Badges", seeder.seedBadges},

		{"Technicians", seeder.seedTechnicians},
		{"Technician Addresses", seeder.seedTechnicianAddresses},
		{"Technician Services", seeder.seedTechnicianServices},
		{"Technician Service Areas", seeder.seedTechnicianServiceAreas},
		{"Technician Badges", seeder.seedTechnicianBadges},
	}

	for _, step := range steps {
		log.Printf("👉 Processing: %s...", step.Name)

		if err := step.Run(); err != nil {
			log.Printf("❌ Failed to seed %s: %v\n", step.Name, err)
			return err
		}

		log.Println("--------------------------------------------------")
	}

	log.Println("✅ All Seeding completed successfully!")
	log.Println("==================================================")
	return nil
}

func (s *Seeder) seedProvinces() error {
	if s.isAlreadySeeded(&province.Province{}, "Provinces") {
		return nil
	}

	type provinceData struct {
		NameTH string `json:"name_th"`
	}

	var items []provinceData
	if err := s.loadJSONFile(provincesFile, &items); err != nil {
		return fmt.Errorf("load provinces: %w", err)
	}

	data := make([]province.Province, 0, len(items))
	for _, item := range items {
		data = append(data, province.Province{NameTH: item.NameTH})
	}

	if err := s.db.Create(&data).Error; err != nil {
		return fmt.Errorf("seed provinces: %w", err)
	}

	log.Printf("   ✓ Seeded %d provinces", len(data))
	return nil
}

func (s *Seeder) seedServiceCategories() error {
	if s.isAlreadySeeded(&servicecategory.ServiceCategory{}, "Service categories") {
		return nil
	}

	type categoryData struct {
		CatName string `json:"cat_name"`
		CatDesc string `json:"cat_desc"`
		IconURL string `json:"icon_url"`
	}

	var items []categoryData
	if err := s.loadJSONFile(categoriesFile, &items); err != nil {
		return fmt.Errorf("load categories: %w", err)
	}

	data := make([]servicecategory.ServiceCategory, 0, len(items))
	for _, item := range items {
		desc := item.CatDesc
		icon := item.IconURL

		data = append(data, servicecategory.ServiceCategory{
			CatName:  item.CatName,
			CatDesc:  &desc,
			IconURL:  &icon,
			IsActive: true,
		})
	}

	if err := s.db.Create(&data).Error; err != nil {
		return fmt.Errorf("seed service categories: %w", err)
	}

	log.Printf("   ✓ Seeded %d service categories", len(data))
	return nil
}

/* -------------------- Services -------------------- */

func (s *Seeder) seedServices() error {
	if s.isAlreadySeeded(&service.Service{}, "Services") {
		return nil
	}

	categoryMap, err := s.loadCategoryMap()
	if err != nil {
		return err
	}

	type serviceData struct {
		Category     string                 `json:"category"`
		Name         string                 `json:"name"`
		Desc         *string                `json:"description"`
		ImageURLs    []string               `json:"image_urls"`
		DefaultPrice map[string]interface{} `json:"default_price"`
		Details      []string               `json:"ser_details"`
		Terms        []string               `json:"additional_terms"`
		Duration     []string               `json:"working_duration"`
	}

	var items []serviceData
	if err := s.loadJSONFile(servicesFile, &items); err != nil {
		return fmt.Errorf("load services: %w", err)
	}

	data := make([]service.Service, 0, len(items))
	for _, item := range items {
		categoryID, ok := categoryMap[item.Category]
		if !ok {
			return fmt.Errorf("category %q not found, please seed categories first", item.Category)
		}

		svc := service.Service{
			SerName:         item.Name,
			SerDescription:  item.Desc,
			ImageURLs:       service.StringArray(item.ImageURLs),
			SerDetails:      service.StringArray(item.Details),
			AdditionalTerms: service.StringArray(item.Terms),
			WorkingDuration: service.StringArray(item.Duration),
			DefaultPrice:    item.DefaultPrice,
			IsActive:        true,
			CategoryID:      categoryID,
		}

		data = append(data, svc)
	}

	if err := s.db.Create(&data).Error; err != nil {
		return fmt.Errorf("seed services: %w", err)
	}

	log.Printf("   ✓ Seeded %d services", len(data))
	return nil
}

func (s *Seeder) seedBadges() error {
	log.Println("   → Seeding badges")

	type badgeData struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		IconURL     string `json:"icon_url"`
		Level       uint   `json:"level"`
		IsActive    bool   `json:"is_active"`
	}

	var items []badgeData
	if err := s.loadJSONFile(badgesFile, &items); err != nil {
		return fmt.Errorf("load badges: %w", err)
	}

	for _, item := range items {
		if err := s.upsertBadge(item.Name, item.Description, item.IconURL, item.Level, item.IsActive); err != nil {
			return err
		}
	}

	var total int64
	if err := s.db.Model(&badge.Badge{}).Count(&total).Error; err == nil {
		log.Printf("   ✓ Seeded/updated badges (total now: %d)", total)
	}

	return nil
}

func (s *Seeder) seedTechnicians() error {
	if s.isAlreadySeeded(&technician.Technician{}, "Technicians") {
		return nil
	}

	var items []technician.Technician
	if err := s.loadJSONFile(techniciansFile, &items); err != nil {
		return fmt.Errorf("load technicians: %w", err)
	}

	if err := s.db.Create(&items).Error; err != nil {
		return fmt.Errorf("seed technicians: %w", err)
	}

	log.Printf("   ✓ Seeded %d technicians", len(items))
	return nil
}

func (s *Seeder) seedTechnicianAddresses() error {
	if s.isAlreadySeeded(&technicianaddress.TechnicianAddress{}, "Technician addresses") {
		return nil
	}

	var items []technicianaddress.TechnicianAddress
	if err := s.loadJSONFile(technicianAddressesFile, &items); err != nil {
		return fmt.Errorf("load technician addresses: %w", err)
	}

	if err := s.db.Create(&items).Error; err != nil {
		return fmt.Errorf("seed technician addresses: %w", err)
	}

	log.Printf("   ✓ Seeded %d technician addresses", len(items))
	return nil
}

func (s *Seeder) seedTechnicianServices() error {
	if s.isAlreadySeeded(&technicianservice.TechnicianService{}, "Technician services") {
		return nil
	}

	var items []technicianservice.TechnicianService
	if err := s.loadJSONFile(technicianServicesFile, &items); err != nil {
		return fmt.Errorf("load technician services: %w", err)
	}

	if err := s.db.Create(&items).Error; err != nil {
		return fmt.Errorf("seed technician services: %w", err)
	}

	log.Printf("   ✓ Seeded %d technician services", len(items))
	return nil
}

func (s *Seeder) seedTechnicianServiceAreas() error {
	if s.isAlreadySeeded(&technicianservicearea.TechnicianServiceArea{}, "Technician service areas") {
		return nil
	}

	type serviceAreaData struct {
		TechnicianID uint `json:"technician_id"`
		ProvinceID   uint `json:"province_id"`
		IsActive     bool `json:"is_active"`
	}

	var items []serviceAreaData

	if err := s.loadJSONFile(technicianServiceAreasFile, &items); err != nil {
		return fmt.Errorf("load technician service areas: %w", err)
	}

	data := make([]technicianservicearea.TechnicianServiceArea, 0, len(items))
	for _, item := range items {

		if item.TechnicianID == 0 || item.ProvinceID == 0 {
			log.Printf("⚠️ Skip item with 0 ID: TechID=%d, ProvID=%d", item.TechnicianID, item.ProvinceID)
			continue
		}

		isActive := item.IsActive

		data = append(data, technicianservicearea.TechnicianServiceArea{
			TechnicianID: item.TechnicianID,
			ProvinceID:   item.ProvinceID,
			IsActive:     isActive,
		})
	}

	if len(data) == 0 {
		log.Println("   ⚠️ No valid service areas to seed (check JSON keys)")
		return nil
	}

	if err := s.db.Create(&data).Error; err != nil {
		return fmt.Errorf("seed technician service areas: %w", err)
	}

	log.Printf("   ✓ Seeded %d technician service areas", len(data))
	return nil
}

func (s *Seeder) seedTechnicianBadges() error {
	if s.isAlreadySeeded(&technicianbadge.TechnicianBadge{}, "Technician badges") {
		return nil
	}

	type techBadgeData struct {
		TechnicianID uint `json:"technician_id"`
		BadgeID      uint `json:"badge_id"`
	}

	var items []techBadgeData
	if err := s.loadJSONFile(technicianBadgesFile, &items); err != nil {
		return fmt.Errorf("load technician badges: %w", err)
	}

	data := make([]technicianbadge.TechnicianBadge, 0, len(items))
	for _, item := range items {

		if item.TechnicianID == 0 || item.BadgeID == 0 {
			log.Printf("⚠️ Skip badge with 0 ID: TechID=%d, BadgeID=%d", item.TechnicianID, item.BadgeID)
			continue
		}

		data = append(data, technicianbadge.TechnicianBadge{
			TechnicianID: item.TechnicianID,
			BadgeID:      item.BadgeID,
		})
	}

	if len(data) == 0 {
		log.Println("   ⚠️ No valid technician badges to seed")
		return nil
	}

	if err := s.db.Create(&data).Error; err != nil {
		return fmt.Errorf("seed technician badges: %w", err)
	}

	log.Printf("   ✓ Seeded %d technician badges", len(data))
	return nil
}

func (s *Seeder) isAlreadySeeded(model interface{}, name string) bool {
	var count int64
	if err := s.db.Model(model).Count(&count).Error; err != nil {
		log.Printf("   ⚠ Error checking %s: %v", name, err)
		return false
	}

	if count > 0 {
		log.Printf("   ⊘ %s already seeded, skipping", name)
		return true
	}
	return false
}

func (s *Seeder) loadJSONFile(filepath string, target interface{}) error {
	content, err := os.ReadFile(filepath)
	if err != nil {
		return fmt.Errorf("read file %s: %w", filepath, err)
	}

	if err := json.Unmarshal(content, target); err != nil {
		return fmt.Errorf("parse JSON from %s: %w", filepath, err)
	}

	return nil
}

func (s *Seeder) loadCategoryMap() (map[string]uint, error) {
	var categories []servicecategory.ServiceCategory
	if err := s.db.Find(&categories).Error; err != nil {
		return nil, fmt.Errorf("read service categories: %w", err)
	}

	categoryMap := make(map[string]uint, len(categories))
	for _, cat := range categories {
		categoryMap[cat.CatName] = cat.ID
	}

	return categoryMap, nil
}

func (s *Seeder) upsertBadge(name, description, iconURL string, level uint, isActive bool) error {
	var existing badge.Badge
	err := s.db.Unscoped().Where("name = ?", name).First(&existing).Error

	switch {
	case err == nil:
		if existing.DeletedAt.Valid {
			if err := s.db.Unscoped().
				Model(&badge.Badge{}).
				Where("id = ?", existing.ID).
				Update("deleted_at", nil).Error; err != nil {
				return fmt.Errorf("restore badge %q: %w", name, err)
			}
		}

		existing.Description = description
		existing.IconURL = iconURL
		existing.Level = level
		existing.IsActive = isActive

		if err := s.db.Save(&existing).Error; err != nil {
			return fmt.Errorf("update badge %q: %w", name, err)
		}

	case err == gorm.ErrRecordNotFound:
		newBadge := badge.Badge{
			Name:        name,
			Description: description,
			IconURL:     iconURL,
			Level:       level,
			IsActive:    isActive,
		}
		if err := s.db.Create(&newBadge).Error; err != nil {
			return fmt.Errorf("create badge %q: %w", name, err)
		}

	default:
		return fmt.Errorf("read badge %q: %w", name, err)
	}

	return nil
}
