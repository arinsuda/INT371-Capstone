package database

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	"gorm.io/gorm"

	badge "changsure-core-service/internal/modules/badge"
	"changsure-core-service/internal/modules/provinces"
	"changsure-core-service/internal/modules/service_categories"
	"changsure-core-service/internal/modules/services"
)

const (
	seedsDir       = "./seeds"
	provincesFile  = seedsDir + "/provinces/province.json"
	categoriesFile = seedsDir + "/categories/category.json"
	servicesFile   = seedsDir + "/services/service.json"
	badgesFile     = seedsDir + "/badges/badge.json"
)

type Seeder struct {
	db *gorm.DB
}

func NewSeeder(db *gorm.DB) *Seeder {
	return &Seeder{db: db}
}

func (d *Database) Seed() error {
	log.Println("🌱 Seeding database...")

	seeder := NewSeeder(d.DB)
	seeders := []func() error{
		seeder.seedProvinces,
		seeder.seedServiceCategories,
		seeder.seedServices,
		seeder.seedBadges,
	}

	for _, seed := range seeders {
		if err := seed(); err != nil {
			return err
		}
	}

	log.Println("✅ Seeding completed successfully")
	return nil
}

func (s *Seeder) seedProvinces() error {
	if s.isAlreadySeeded(&provinces.Province{}, "Provinces") {
		return nil
	}

	type provinceData struct {
		NameTH string `json:"name_th"`
	}

	var items []provinceData
	if err := s.loadJSONFile(provincesFile, &items); err != nil {
		return fmt.Errorf("load provinces: %w", err)
	}

	data := make([]provinces.Province, 0, len(items))
	for _, item := range items {
		data = append(data, provinces.Province{NameTH: item.NameTH})
	}

	if err := s.db.Create(&data).Error; err != nil {
		return fmt.Errorf("seed provinces: %w", err)
	}

	log.Printf("   ✓ Seeded %d provinces", len(data))
	return nil
}

func (s *Seeder) seedServiceCategories() error {
	if s.isAlreadySeeded(&service_categories.ServiceCategory{}, "Service categories") {
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

	data := make([]service_categories.ServiceCategory, 0, len(items))
	for _, item := range items {
		desc := item.CatDesc
		icon := item.IconURL

		data = append(data, service_categories.ServiceCategory{
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
	if s.isAlreadySeeded(&services.Service{}, "Services") {
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

	data := make([]services.Service, 0, len(items))
	for _, item := range items {
		categoryID, ok := categoryMap[item.Category]
		if !ok {
			return fmt.Errorf("category %q not found, please seed categories first", item.Category)
		}

		svc := services.Service{
			SerName:         item.Name,
			SerDescription:  item.Desc,
			ImageURLs:       services.StringArray(item.ImageURLs),
			SerDetails:      services.StringArray(item.Details),
			AdditionalTerms: services.StringArray(item.Terms),
			WorkingDuration: services.StringArray(item.Duration),
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
	var categories []service_categories.ServiceCategory
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
