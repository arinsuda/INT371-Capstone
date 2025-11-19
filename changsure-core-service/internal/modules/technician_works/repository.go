package technician_works

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, w *TechnicianWork, imgs []TechnicianWorkImage) error
	Update(ctx context.Context, w *TechnicianWork, replaceImages *[]TechnicianWorkImage) error
	FindByID(ctx context.Context, id, technicianID uint) (*TechnicianWork, error)
	ListByTechnician(ctx context.Context, technicianID uint, q ListTechnicianWorksQuery, page, perPage int) ([]TechnicianWork, int64, error)
	SoftDelete(ctx context.Context, id, technicianID uint) error
	HardDelete(ctx context.Context, id, technicianID uint) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Create(ctx context.Context, w *TechnicianWork, imgs []TechnicianWorkImage) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(w).Error; err != nil {
			return err
		}
		if len(imgs) > 0 {
			for i := range imgs {
				imgs[i].WorkID = w.ID
			}
			if err := tx.Create(&imgs).Error; err != nil {
				return err
			}
		}
		return nil
	})
}

func (r *repository) Update(ctx context.Context, w *TechnicianWork, replaceImages *[]TechnicianWorkImage) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(w).Error; err != nil {
			return err
		}
		if replaceImages != nil {
			if err := tx.
				Where("work_id = ?", w.ID).
				Delete(&TechnicianWorkImage{}).Error; err != nil {
				return err
			}
			if len(*replaceImages) > 0 {
				for i := range *replaceImages {
					(*replaceImages)[i].WorkID = w.ID
				}
				if err := tx.Create(replaceImages).Error; err != nil {
					return err
				}
			}
		}
		return nil
	})
}

func (r *repository) FindByID(ctx context.Context, id, technicianID uint) (*TechnicianWork, error) {
	var w TechnicianWork
	if err := r.db.WithContext(ctx).
		Preload("Service").
		Preload("Province").
		Preload("Images", "deleted_at IS NULL").
		Where("id = ? AND technician_id = ?", id, technicianID).
		First(&w).Error; err != nil {
		return nil, err
	}
	return &w, nil
}

func (r *repository) ListByTechnician(ctx context.Context, technicianID uint, q ListTechnicianWorksQuery, page, perPage int) ([]TechnicianWork, int64, error) {
	if page <= 0 {
		page = 1
	}
	if perPage <= 0 || perPage > 100 {
		perPage = 10
	}

	var (
		items []TechnicianWork
		total int64
	)

	tx := r.db.WithContext(ctx).
		Model(&TechnicianWork{}).
		Where("technician_id = ? AND deleted_at IS NULL", technicianID)

	if q.ServiceID != nil {
		tx = tx.Where("service_id = ?", *q.ServiceID)
	}
	if q.ProvinceID != nil {
		tx = tx.Where("province_id = ?", *q.ProvinceID)
	}

	if err := tx.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if err := tx.
		Preload("Service").
		Preload("Province").
		Preload("Images", "deleted_at IS NULL").
		Order("created_at DESC").
		Limit(perPage).
		Offset((page - 1) * perPage).
		Find(&items).Error; err != nil {
		return nil, 0, err
	}

	return items, total, nil
}

func (r *repository) SoftDelete(ctx context.Context, id, technicianID uint) error {
	return r.db.WithContext(ctx).
		Where("id = ? AND technician_id = ?", id, technicianID).
		Delete(&TechnicianWork{}).Error
}

func (r *repository) HardDelete(ctx context.Context, id, technicianID uint) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Unscoped().
			Where("work_id = ?", id).
			Delete(&TechnicianWorkImage{}).Error; err != nil {
			return err
		}
		if err := tx.Unscoped().
			Where("id = ? AND technician_id = ?", id, technicianID).
			Delete(&TechnicianWork{}).Error; err != nil {
			return err
		}
		return nil
	})
}
