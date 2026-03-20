package database

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	addressshared "changsure-core-service/internal/modules/address_shared"
	"changsure-core-service/internal/modules/admin"
	badge "changsure-core-service/internal/modules/badge"
	criminalcheck "changsure-core-service/internal/modules/criminal_check"
	district "changsure-core-service/internal/modules/district"
	"changsure-core-service/internal/modules/document"
	"changsure-core-service/internal/modules/province"
	"changsure-core-service/internal/modules/service"
	servicecategory "changsure-core-service/internal/modules/service_category"
	subdistrict "changsure-core-service/internal/modules/sub_district"
	"changsure-core-service/internal/modules/technician"
	technicianaddress "changsure-core-service/internal/modules/technician_address"
	technicianbadge "changsure-core-service/internal/modules/technician_badge"
	technicianservice "changsure-core-service/internal/modules/technician_service"
	technicianservicearea "changsure-core-service/internal/modules/technician_service_area"
	timeslot "changsure-core-service/internal/modules/time_slot"
)

const seedsDir = "./seeds"

type Seeder struct {
	db *gorm.DB
}

func NewSeeder(db *gorm.DB) *Seeder {
	return &Seeder{db: db}
}

func loadSeedFile[T any](path string) ([]T, error) {
	fullPath := fmt.Sprintf("%s/%s", seedsDir, path)
	content, err := os.ReadFile(fullPath)
	if err != nil {
		return nil, fmt.Errorf("read file %s: %w", fullPath, err)
	}
	var data []T
	if err := json.Unmarshal(content, &data); err != nil {
		return nil, fmt.Errorf("parse json %s: %w", fullPath, err)
	}
	return data, nil
}

func (d *Database) Seed() error {
	log.Println("🌱 Starting Database Seeding Process...")
	s := NewSeeder(d.DB)

	steps := []struct {
		Name string
		Fn   func() error
	}{
		{"Provinces", s.seedProvinces},
		{"Districts", s.seedDistricts},
		{"SubDistricts", s.seedSubDistricts},
		{"Time Slots", s.seedTimeSlots},
		{"Service Categories", s.seedServiceCategories},
		{"Services", s.seedServices},
		{"Badges", s.seedBadges},
		{"Technicians", s.seedTechnicians},
		{"Technician Addresses", s.seedTechnicianAddresses},
		{"Technician Services", s.seedTechnicianServices},
		{"Technician Service Areas", s.seedTechnicianServiceAreas},
		{"Technician Badges", s.seedTechnicianBadges},
		{"Documents", s.seedDocuments},
		{"Criminal Records", s.seedCriminalRecords},
		{"Admins", s.seedAdmins},
	}

	for _, step := range steps {
		log.Printf("👉 Processing: %s...", step.Name)
		if err := step.Fn(); err != nil {
			return fmt.Errorf("failed to seed %s: %w", step.Name, err)
		}
	}

	log.Println("✅ All Seeding completed successfully!")
	return nil
}

func (s *Seeder) seedProvinces() error {
	if s.isSeeded(&province.Province{}) {
		return nil
	}

	items, err := loadSeedFile[struct {
		NameTH string `json:"name_th"`
	}]("provinces/province.json")
	if err != nil {
		return err
	}

	var data []province.Province
	for _, item := range items {
		data = append(data, province.Province{NameTH: item.NameTH})
	}
	return s.db.CreateInBatches(data, 100).Error
}

func (s *Seeder) seedDistricts() error {
	if s.isSeeded(&district.District{}) {
		return nil
	}

	type DistrictInput struct {
		NameTH         string `json:"name_th"`
		ProvinceNameTH string `json:"province_name_th"`
	}
	items, err := loadSeedFile[DistrictInput]("districts/district.json")
	if err != nil {
		return err
	}

	provMap, err := s.getProvinceMap()
	if err != nil {
		return err
	}

	var data []district.District
	for _, item := range items {
		if item.NameTH == "" {
			continue
		}
		pid, ok := provMap[item.ProvinceNameTH]
		if !ok {
			return fmt.Errorf("province %q not found", item.ProvinceNameTH)
		}
		data = append(data, district.District{NameTH: item.NameTH, ProvinceID: pid})
	}
	return s.db.CreateInBatches(data, 100).Error
}

func (s *Seeder) seedSubDistricts() error {
	if s.isSeeded(&subdistrict.SubDistrict{}) {
		return nil
	}

	type SubDistInput struct {
		NameTH         string `json:"name_th"`
		PostalCode     string `json:"postal_code"`
		DistrictNameTH string `json:"district_name_th"`
		ProvinceNameTH string `json:"province_name_th"`
	}
	items, err := loadSeedFile[SubDistInput]("sub_districts/sub_district.json")
	if err != nil {
		return err
	}

	var districts []district.District
	if err := s.db.Preload("Province").Find(&districts).Error; err != nil {
		return err
	}

	distMap := make(map[string]uint)
	for _, d := range districts {
		key := fmt.Sprintf("%s|%s", d.Province.NameTH, d.NameTH)
		distMap[key] = d.ID
	}

	var data []subdistrict.SubDistrict
	for _, item := range items {
		key := fmt.Sprintf("%s|%s", item.ProvinceNameTH, item.DistrictNameTH)
		did, ok := distMap[key]
		if !ok {
			continue
		}

		data = append(data, subdistrict.SubDistrict{
			NameTH: item.NameTH, PostalCode: item.PostalCode, DistrictID: did,
		})
	}
	return s.db.CreateInBatches(data, 100).Error
}

func (s *Seeder) seedTimeSlots() error {
	if s.isSeeded(&timeslot.TimeSlot{}) {
		return nil
	}

	items, err := loadSeedFile[timeslot.TimeSlot]("time_slots/time_slots_seed.json")
	if err != nil {
		return err
	}

	return s.db.CreateInBatches(&items, 100).Error
}

func (s *Seeder) seedServiceCategories() error {

	type CategoryInput struct {
		CatName string  `json:"cat_name"`
		CatDesc *string `json:"cat_desc"`
		IconURL *string `json:"icon_url"`
	}

	items, err := loadSeedFile[CategoryInput]("categories/category.json")
	if err != nil {
		return err
	}

	data := make([]servicecategory.ServiceCategory, 0, len(items))
	for _, it := range items {
		name := strings.TrimSpace(it.CatName)
		if name == "" {
			continue
		}
		data = append(data, servicecategory.ServiceCategory{
			CatName:  name,
			CatDesc:  it.CatDesc,
			IconURL:  it.IconURL,
			IsActive: true,
		})
	}

	if len(data) == 0 {
		return fmt.Errorf("no valid service categories loaded from seeds/categories/category.json (check json keys)")
	}

	return s.db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "cat_name"}},
		DoUpdates: clause.AssignmentColumns([]string{"cat_description", "icon_url", "is_active", "updated_at"}),
	}).Create(&data).Error
}

func (s *Seeder) seedServices() error {
	if s.isSeeded(&service.Service{}) {
		return nil
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

	items, err := loadSeedFile[serviceData]("services/service.json")
	if err != nil {
		return err
	}

	var cats []servicecategory.ServiceCategory
	s.db.Find(&cats)
	catMap := make(map[string]uint)
	for _, c := range cats {
		catMap[c.CatName] = c.ID
	}

	var data []service.Service
	for _, item := range items {
		cid, ok := catMap[item.Category]
		if !ok {
			return fmt.Errorf("category %q not found", item.Category)
		}

		data = append(data, service.Service{
			SerName:         item.Name,
			SerDescription:  item.Desc,
			ImageURLs:       service.StringArray(item.ImageURLs),
			SerDetails:      service.StringArray(item.Details),
			AdditionalTerms: service.StringArray(item.Terms),
			WorkingDuration: service.StringArray(item.Duration),
			DefaultPrice:    item.DefaultPrice,
			IsActive:        true,
			CategoryID:      cid,
		})
	}
	return s.db.Create(&data).Error
}

func (s *Seeder) seedBadges() error {
	items, err := loadSeedFile[badge.Badge]("badges/badge.json")
	if err != nil {
		return err
	}

	for _, item := range items {
		var existing badge.Badge
		if err := s.db.Unscoped().Where("name = ?", item.Name).First(&existing).Error; err == nil {
			existing.Description = item.Description
			existing.IconURL = item.IconURL
			existing.Level = item.Level
			existing.IsActive = item.IsActive
			existing.DeletedAt = gorm.DeletedAt{}
			s.db.Save(&existing)
		} else {
			s.db.Create(&item)
		}
	}
	return nil
}

func (s *Seeder) seedTechnicians() error {
	if s.isSeeded(&technician.Technician{}) {
		return nil
	}

	type TechnicianSeed struct {
		Firstname    string `json:"firstname"`
		Lastname     string `json:"lastname"`
		Email        string `json:"email"`
		PasswordHash string `json:"password_hash"`
		IsAvailable  bool   `json:"is_available"`
		IsVerified   bool   `json:"is_verified"`
	}

	items, err := loadSeedFile[TechnicianSeed]("technicians/technician.json")
	if err != nil {
		return err
	}

	technicians := make([]technician.Technician, 0, len(items))
	for _, item := range items {
		email := item.Email
		technicians = append(technicians, technician.Technician{
			FirstName:    item.Firstname,
			LastName:     item.Lastname,
			Email:        &email,
			PasswordHash: item.PasswordHash,
			IsAvailable:  item.IsAvailable,
			IsVerified:   item.IsVerified,
		})
	}

	return s.db.CreateInBatches(technicians, 100).Error
}

func (s *Seeder) seedTechnicianAddresses() error {
	if s.isSeeded(&technicianaddress.TechnicianAddress{}) {
		return nil
	}

	type TechAddrInput struct {
		TechnicianID    uint     `json:"technician_id"`
		HouseNumber     string   `json:"house_number"`
		Soi             *string  `json:"soi"`
		Road            *string  `json:"road"`
		SubDistrictName string   `json:"sub_district"`
		DistrictName    string   `json:"district"`
		ProvinceName    string   `json:"province"`
		PostalCode      string   `json:"postal_code"`
		Latitude        *float64 `json:"latitude"`
		Longitude       *float64 `json:"longitude"`
		IsPrimary       bool     `json:"is_primary"`
		ProvinceID      uint     `json:"province_id"`
	}

	items, err := loadSeedFile[TechAddrInput]("technicians/technician_address.json")
	if err != nil {
		return err
	}

	lookup, err := newAddressLookup(s.db)
	if err != nil {
		return err
	}

	var data []technicianaddress.TechnicianAddress

	for i, item := range items {
		if item.TechnicianID == 0 {
			continue
		}

		provID, distID, subID, err := lookup.resolve(item.ProvinceName, item.DistrictName, item.SubDistrictName, item.PostalCode)

		if provID == 0 && item.ProvinceID != 0 {
			provID = item.ProvinceID
		}

		if err != nil {
			log.Printf("⚠️ Skip addr #%d (TechID %d): %v", i, item.TechnicianID, err)
			continue
		}

		houseNum := item.HouseNumber

		data = append(data, technicianaddress.TechnicianAddress{
			TechnicianID: item.TechnicianID,
			AddressFields: addressshared.AddressFields{
				HouseNumber:   &houseNum,
				Soi:           item.Soi,
				Road:          item.Road,
				ProvinceID:    &provID,
				DistrictID:    &distID,
				SubDistrictID: &subID,
				Latitude:      item.Latitude,
				Longitude:     item.Longitude,
				IsPrimary:     item.IsPrimary,
			},
		})
	}

	return s.db.CreateInBatches(data, 100).Error
}

func (s *Seeder) seedTechnicianServices() error {
	if s.isSeeded(&technicianservice.TechnicianService{}) {
		return nil
	}
	items, err := loadSeedFile[technicianservice.TechnicianService]("technicians/technician_service.json")
	if err != nil {
		return err
	}
	return s.db.Create(&items).Error
}

func (s *Seeder) seedTechnicianServiceAreas() error {
	if s.isSeeded(&technicianservicearea.TechnicianServiceArea{}) {
		return nil
	}

	type Input struct {
		TechnicianID uint  `json:"technician_id"`
		ProvinceID   uint  `json:"province_id"`
		IsActive     *bool `json:"is_active"`
	}

	items, err := loadSeedFile[Input]("technicians/technician_service_area.json")
	if err != nil {
		return err
	}

	data := make([]technicianservicearea.TechnicianServiceArea, 0, len(items))

	for i, it := range items {
		if it.TechnicianID == 0 {
			continue
		}
		if it.ProvinceID == 0 {
			log.Printf("⚠️ Skip service_area #%d: empty province_id (tech_id=%d)", i, it.TechnicianID)
			continue
		}

		active := true
		if it.IsActive != nil {
			active = *it.IsActive
		}

		data = append(data, technicianservicearea.TechnicianServiceArea{
			TechnicianID: it.TechnicianID,
			ProvinceID:   it.ProvinceID,
			IsActive:     active,
		})
	}

	if len(data) == 0 {
		log.Println("ℹ️ No technician service areas to seed")
		return nil
	}

	return s.db.CreateInBatches(&data, 100).Error
}

func (s *Seeder) seedTechnicianBadges() error {
	if s.isSeeded(&technicianbadge.TechnicianBadge{}) {
		return nil
	}

	items, err := loadSeedFile[technicianbadge.TechnicianBadge]("technicians/technician_badge.json")
	if err != nil {
		return err
	}

	var techIDs []uint
	if err := s.db.Model(&technician.Technician{}).Pluck("id", &techIDs).Error; err != nil {
		return err
	}
	techSet := make(map[uint]struct{}, len(techIDs))
	for _, id := range techIDs {
		techSet[id] = struct{}{}
	}

	filtered := make([]technicianbadge.TechnicianBadge, 0, len(items))
	for i, it := range items {
		if it.TechnicianID == 0 {
			continue
		}
		if _, ok := techSet[it.TechnicianID]; !ok {
			log.Printf("⚠️ Skip technician_badge #%d: technician_id=%d not found", i, it.TechnicianID)
			continue
		}
		filtered = append(filtered, it)
	}

	if len(filtered) == 0 {
		log.Println("ℹ️ No technician badges to seed (all invalid or empty)")
		return nil
	}

	return s.db.CreateInBatches(&filtered, 100).Error
}

func (s *Seeder) seedDocuments() error {
	type VersionSeed struct {
		Version     int             `json:"version"`
		Locale      string          `json:"locale"`
		IsPublished bool            `json:"is_published"`
		Content     json.RawMessage `json:"content"`
	}

	type DocumentSeed struct {
		Type     string        `json:"type"`
		Slug     string        `json:"slug"`
		Versions []VersionSeed `json:"versions"`
	}

	type SeedFile struct {
		Documents []DocumentSeed `json:"documents"`
	}

	fullPath := fmt.Sprintf("%s/documents/onboard.json", seedsDir)
	content, err := os.ReadFile(fullPath)
	if err != nil {
		return fmt.Errorf("read file %s: %w", fullPath, err)
	}

	var seedFile SeedFile
	if err := json.Unmarshal(content, &seedFile); err != nil {
		return fmt.Errorf("parse json: %w", err)
	}

	for _, docSeed := range seedFile.Documents {
		var doc document.Document
		err := s.db.Where("slug = ?", docSeed.Slug).First(&doc).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			doc = document.Document{
				ID:   uuid.New(),
				Type: docSeed.Type,
				Slug: docSeed.Slug,
			}
			if err := s.db.Create(&doc).Error; err != nil {
				return fmt.Errorf("create document %s: %w", docSeed.Slug, err)
			}
			log.Printf("  ✅ Created document: %s", docSeed.Slug)
		} else if err != nil {
			return fmt.Errorf("query document %s: %w", docSeed.Slug, err)
		} else {
			log.Printf("  ⏭️  Document already exists: %s", docSeed.Slug)
		}

		for _, vs := range docSeed.Versions {
			var existing document.DocumentVersion
			err := s.db.
				Where("document_id = ? AND version = ? AND locale = ?", doc.ID, vs.Version, vs.Locale).
				First(&existing).Error

			if errors.Is(err, gorm.ErrRecordNotFound) {
				v := document.DocumentVersion{
					DocumentID:  doc.ID,
					Version:     vs.Version,
					Locale:      vs.Locale,
					Content:     datatypes.JSON(vs.Content),
					IsPublished: vs.IsPublished,
				}
				if err := s.db.Create(&v).Error; err != nil {
					return fmt.Errorf("create version %d for %s: %w", vs.Version, docSeed.Slug, err)
				}
				log.Printf("    ✅ Created version %d (%s)", vs.Version, vs.Locale)
			} else if err != nil {
				return fmt.Errorf("query version: %w", err)
			} else {
				log.Printf("    ⏭️  Version %d (%s) already exists", vs.Version, vs.Locale)
			}
		}
	}

	return nil
}

func (s *Seeder) seedCriminalRecords() error {
	if s.isSeeded(&criminalcheck.CriminalBlacklist{}) {
		return nil
	}

	type RecordInput struct {
		NationalID string `json:"national_id"`
		FullName   string `json:"full_name"`
		Status     string `json:"status"`
		Note       string `json:"note"`
	}

	type SeedFile struct {
		Records []RecordInput `json:"criminal_records"`
	}

	fullPath := fmt.Sprintf("%s/criminal_records/criminal.json", seedsDir)
	content, err := os.ReadFile(fullPath)
	if err != nil {
		return fmt.Errorf("read criminal records seed: %w", err)
	}

	var seedFile SeedFile
	if err := json.Unmarshal(content, &seedFile); err != nil {
		return fmt.Errorf("parse criminal records seed: %w", err)
	}

	data := make([]criminalcheck.CriminalBlacklist, 0, len(seedFile.Records))
	for _, r := range seedFile.Records {
		if r.NationalID == "" {
			continue
		}
		data = append(data, criminalcheck.CriminalBlacklist{
			NationalID: r.NationalID,
			FullName:   r.FullName,
			Note:       r.Note,
		})
	}

	return s.db.CreateInBatches(data, 100).Error
}

func (s *Seeder) seedAdmins() error {
	if s.isSeeded(&admin.Admin{}) {
		return nil
	}

	type AdminSeed struct {
		FirstName    string `json:"firstname"`
		LastName     string `json:"lastname"`
		Email        string `json:"email"`
		PasswordHash string `json:"password_hash"`
	}

	items, err := loadSeedFile[AdminSeed]("admins/admin.json")
	if err != nil {
		return err
	}

	data := make([]admin.Admin, 0, len(items))
	for _, item := range items {
		data = append(data, admin.Admin{
			FirstName:    item.FirstName,
			LastName:     item.LastName,
			Email:        item.Email,
			PasswordHash: item.PasswordHash,
		})
	}

	return s.db.CreateInBatches(data, 100).Error
}

func (s *Seeder) isSeeded(model interface{}) bool {
	var count int64
	tx := s.db.Model(model).Count(&count)
	if tx.Error != nil {
		log.Printf("⚠️ isSeeded count error: %v", tx.Error)
		return false
	}
	return count > 0
}

func (s *Seeder) getProvinceMap() (map[string]uint, error) {
	var provs []province.Province
	if err := s.db.Find(&provs).Error; err != nil {
		return nil, err
	}
	m := make(map[string]uint)
	for _, p := range provs {
		m[p.NameTH] = p.ID
	}
	return m, nil
}

type addressLookup struct {
	provMap            map[string]uint
	distMap            map[string]uint
	subDistMap         map[string]uint
	subDistMapNoPostal map[string]uint
}

func newAddressLookup(db *gorm.DB) (*addressLookup, error) {
	l := &addressLookup{
		provMap:            make(map[string]uint),
		distMap:            make(map[string]uint),
		subDistMap:         make(map[string]uint),
		subDistMapNoPostal: make(map[string]uint),
	}

	var provs []province.Province
	if err := db.Find(&provs).Error; err != nil {
		return nil, err
	}
	for _, p := range provs {
		l.provMap[normalizeTH(p.NameTH)] = p.ID
	}

	var dists []district.District
	if err := db.Find(&dists).Error; err != nil {
		return nil, err
	}
	for _, d := range dists {
		normName := normalizeTH(d.NameTH)
		l.distMap[fmt.Sprintf("%d|%s", d.ProvinceID, normName)] = d.ID

		base := stripThaiPrefix(normName, "เขต", "อำเภอ")
		if base != "" {
			l.distMap[fmt.Sprintf("%d|%s", d.ProvinceID, base)] = d.ID
		}
	}

	var subs []subdistrict.SubDistrict
	if err := db.Find(&subs).Error; err != nil {
		return nil, err
	}
	for _, s := range subs {
		n := normalizeTH(s.NameTH)
		p := normalizeTH(s.PostalCode)

		l.subDistMap[fmt.Sprintf("%d|%s|%s", s.DistrictID, n, p)] = s.ID
		l.subDistMapNoPostal[fmt.Sprintf("%d|%s", s.DistrictID, n)] = s.ID

		base := stripThaiPrefix(n, "แขวง", "ตำบล")
		if base != "" {
			l.subDistMap[fmt.Sprintf("%d|%s|%s", s.DistrictID, base, p)] = s.ID
			l.subDistMapNoPostal[fmt.Sprintf("%d|%s", s.DistrictID, base)] = s.ID
		}
	}
	return l, nil
}

func (l *addressLookup) resolve(provName, distName, subName, postal string) (uint, uint, uint, error) {
	provID, ok := l.provMap[normalizeTH(provName)]
	if !ok {
		return 0, 0, 0, fmt.Errorf("province not found: %s", provName)
	}

	distName = normalizeTH(distName)
	distID, ok := l.distMap[fmt.Sprintf("%d|%s", provID, distName)]
	if !ok {
		base := stripThaiPrefix(distName, "เขต", "อำเภอ")
		if base != "" {
			distID, ok = l.distMap[fmt.Sprintf("%d|%s", provID, base)]
		}
	}
	if !ok {
		return provID, 0, 0, fmt.Errorf("district not found: %s", distName)
	}

	subName = normalizeTH(subName)
	postal = normalizeTH(postal)

	subID, ok := l.subDistMap[fmt.Sprintf("%d|%s|%s", distID, subName, postal)]
	if !ok {
		subID, ok = l.subDistMapNoPostal[fmt.Sprintf("%d|%s", distID, subName)]
	}

	if !ok {
		return provID, distID, 0, fmt.Errorf("subdistrict not found: %s", subName)
	}

	return provID, distID, subID, nil
}
