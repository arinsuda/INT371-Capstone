package technicianposts

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, p *TechnicianPost, images []TechnicianPostImage) error
	Update(ctx context.Context, p *TechnicianPost, replaceImages *[]TechnicianPostImage) error
	FindByID(ctx context.Context, id, techID uint) (*TechnicianPost, error)
	ListByTechnician(ctx context.Context, techID uint, q ListTechnicianPostsQuery, page, perPage int) ([]TechnicianPost, int64, error)
	SoftDelete(ctx context.Context, id, techID uint) error
	HardDelete(ctx context.Context, id, techID uint) error
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Create(ctx context.Context, p *TechnicianPost, imgs []TechnicianPostImage) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(p).Error; err != nil {
			return err
		}

		for i := range imgs {
			imgs[i].PostID = p.ID
		}
		return tx.Create(&imgs).Error
	})
}

func (r *repository) Update(ctx context.Context, p *TechnicianPost, replace *[]TechnicianPostImage) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(p).Error; err != nil {
			return err
		}

		if replace != nil {
			if err := tx.Where("post_id = ?", p.ID).
				Delete(&TechnicianPostImage{}).Error; err != nil {
				return err
			}
			for i := range *replace {
				(*replace)[i].PostID = p.ID
			}
			return tx.Create(replace).Error
		}

		return nil
	})
}

func (r *repository) FindByID(ctx context.Context, id, techID uint) (*TechnicianPost, error) {
	var p TechnicianPost

	if err := r.db.WithContext(ctx).
		Preload("Service").
		Preload("Province").
		Preload("Images", "deleted_at IS NULL").
		Where("id = ? AND technician_id = ?", id, techID).
		First(&p).Error; err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *repository) ListByTechnician(ctx context.Context, techID uint, q ListTechnicianPostsQuery, page, perPage int) ([]TechnicianPost, int64, error) {
	var (
		posts []TechnicianPost
		total int64
	)

	tx := r.db.WithContext(ctx).
		Model(&TechnicianPost{}).
		Where("technician_id = ? AND deleted_at IS NULL", techID)

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
		Find(&posts).Error; err != nil {
		return nil, 0, err
	}

	return posts, total, nil
}

func (r *repository) SoftDelete(ctx context.Context, id, techID uint) error {
	return r.db.WithContext(ctx).
		Where("id = ? AND technician_id = ?", id, techID).
		Delete(&TechnicianPost{}).Error
}

func (r *repository) HardDelete(ctx context.Context, id, techID uint) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Unscoped().
			Where("post_id = ?", id).
			Delete(&TechnicianPostImage{}).Error; err != nil {
			return err
		}

		return tx.Unscoped().
			Where("id = ? AND technician_id = ?", id, techID).
			Delete(&TechnicianPost{}).Error
	})
}
