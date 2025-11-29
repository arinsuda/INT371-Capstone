package technician_service_areas

import (
	"fmt"
	"gorm.io/gorm"
)

type Repository interface {
	ReplaceForTech(tx *gorm.DB, techID uint, provinceIDs []uint) error
	ListByTech(techID uint) ([]TechnicianServiceArea, error)
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &repository{db: db} }

func (r *repository) ReplaceForTech(tx *gorm.DB, techID uint, provinceIDs []uint) error {
	if tx == nil {
		tx = r.db
	}

	var existing []uint
	if len(provinceIDs) > 0 {
		if err := tx.Table("provinces").Where("id IN ?", provinceIDs).Pluck("id", &existing).Error; err != nil {
			return fmt.Errorf("failed to verify provinces: %v", err)
		}
	}

	missing := diffUint(provinceIDs, existing)
	if len(missing) > 0 {
		return fmt.Errorf("invalid province_ids: %v not found", missing)
	}

	if err := tx.Where("technician_id = ?", techID).Delete(&TechnicianServiceArea{}).Error; err != nil {
		return err
	}

	for _, pid := range provinceIDs {
		rec := &TechnicianServiceArea{TechnicianID: techID, ProvinceID: pid, IsActive: true}
		if err := tx.Create(rec).Error; err != nil {
			return err
		}
	}

	return nil
}

func (r *repository) ListByTech(techID uint) ([]TechnicianServiceArea, error) {
	var list []TechnicianServiceArea
	err := r.db.Where("technician_id = ?", techID).Find(&list).Error
	return list, err
}

func diffUint(all, found []uint) []uint {
	if len(all) == 0 {
		return nil
	}
	set := make(map[uint]struct{}, len(found))
	for _, v := range found {
		set[v] = struct{}{}
	}
	var missing []uint
	for _, v := range all {
		if _, ok := set[v]; !ok {
			missing = append(missing, v)
		}
	}
	return missing
}
