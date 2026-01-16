package technicianposts

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	DB() *gorm.DB

	GetPost(ctx context.Context, postID, technicianID uint) (*TechnicianPost, error)
	CreatePost(ctx context.Context, post *TechnicianPost) error
	UpdatePost(ctx context.Context, post *TechnicianPost) error

	AddPostImages(ctx context.Context, images []TechnicianPostImage) error
	RemovePostImages(ctx context.Context, postID uint) error
	RemovePostImagesByID(ctx context.Context, postID uint, imageIDs []uint) error

	ListPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery, page, perPage int) ([]TechnicianPost, int64, error)

	SoftDeletePost(ctx context.Context, postID, technicianID uint) error
	HardDeletePost(ctx context.Context, postID, technicianID uint) error

	ListPublicPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery, page, perPage int) ([]TechnicianPost, int64, error)
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) DB() *gorm.DB {
	return r.db
}

func (r *repository) GetPost(ctx context.Context, postID, technicianID uint) (*TechnicianPost, error) {
	var post TechnicianPost

	err := r.db.WithContext(ctx).
		Preload("Service").
		Preload("Category").
		Preload("Province").
		Preload("Images", "deleted_at IS NULL").
		Where("id = ? AND technician_id = ?", postID, technicianID).
		First(&post).Error

	if err != nil {
		return nil, err
	}
	return &post, nil
}

func (r *repository) ListPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery, page, perPage int) ([]TechnicianPost, int64, error) {
	var posts []TechnicianPost
	var total int64

	tx := r.db.WithContext(ctx).Model(&TechnicianPost{}).
		Where("technician_posts.technician_id = ? AND technician_posts.deleted_at IS NULL", techID)

	// if q.CategoryID != nil {
	// 	tx = tx.Joins("JOIN services ON services.id = technician_posts.service_id").
	// 		Where("services.category_id = ?", *q.CategoryID)
	// }

	if q.CategoryID != nil {
		tx = tx.Where("technician_posts.service_category_id = ?", *q.CategoryID)
	}

	if q.ServiceID != nil {
		tx = tx.Where("technician_posts.service_id = ?", *q.ServiceID)
	}
	if q.ProvinceID != nil {
		tx = tx.Where("technician_posts.province_id = ?", *q.ProvinceID)
	}
	if q.IsPublished != nil {
		tx = tx.Where("technician_posts.is_published = ?", *q.IsPublished)
	}

	if q.Search != "" {
		keyword := "%" + q.Search + "%"
		tx = tx.Where("(technician_posts.title LIKE ? OR technician_posts.description LIKE ?)", keyword, keyword)
	}

	if err := tx.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if err := tx.
		Preload("Service").
		Preload("Category").
		Preload("Province").
		Preload("Images", "deleted_at IS NULL").
		Order("technician_posts.created_at DESC").
		Limit(perPage).Offset((page - 1) * perPage).
		Find(&posts).Error; err != nil {
		return nil, 0, err
	}

	return posts, total, nil
}

func (r *repository) CreatePost(ctx context.Context, post *TechnicianPost) error {
	return r.db.WithContext(ctx).Create(post).Error
}

func (r *repository) UpdatePost(ctx context.Context, post *TechnicianPost) error {
	return r.db.WithContext(ctx).
		Model(post).
		Updates(map[string]interface{}{
			"title":               post.Title,
			"description":         post.Description,
			"service_category_id": post.ServiceCategoryID,
			"service_id":          post.ServiceID,
			"province_id":         post.ProvinceID,
			"is_published":        post.IsPublished,
		}).Error
}

func (r *repository) AddPostImages(ctx context.Context, images []TechnicianPostImage) error {
	return r.db.WithContext(ctx).Create(&images).Error
}

func (r *repository) RemovePostImages(ctx context.Context, postID uint) error {
	return r.db.WithContext(ctx).
		Where("post_id = ?", postID).
		Delete(&TechnicianPostImage{}).Error
}

func (r *repository) RemovePostImagesByID(ctx context.Context, postID uint, imageIDs []uint) error {
	if len(imageIDs) == 0 {
		return nil
	}
	return r.db.WithContext(ctx).
		Where("post_id = ? AND id IN ?", postID, imageIDs).
		Delete(&TechnicianPostImage{}).Error
}

func (r *repository) SoftDeletePost(ctx context.Context, postID, technicianID uint) error {
	return r.db.WithContext(ctx).
		Where("id = ? AND technician_id = ?", postID, technicianID).
		Delete(&TechnicianPost{}).Error
}

func (r *repository) HardDeletePost(ctx context.Context, postID, technicianID uint) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {

		if err := tx.Unscoped().
			Where("post_id = ?", postID).
			Delete(&TechnicianPostImage{}).Error; err != nil {
			return err
		}

		return tx.Unscoped().
			Where("id = ? AND technician_id = ?", postID, technicianID).
			Delete(&TechnicianPost{}).Error
	})
}

func (r *repository) ListPublicPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery, page, perPage int) ([]TechnicianPost, int64, error) {
	var posts []TechnicianPost
	var total int64

	tx := r.db.WithContext(ctx).Model(&TechnicianPost{}).
		Where("technician_posts.technician_id = ? AND technician_posts.is_published = ? AND technician_posts.deleted_at IS NULL", techID, true)

	if q.CategoryID != nil {
		tx = tx.Where("technician_posts.service_category_id = ?", *q.CategoryID)
	}

	if q.ServiceID != nil {
		tx = tx.Where("technician_posts.service_id = ?", *q.ServiceID)
	}

	if q.ProvinceID != nil {
		tx = tx.Where("technician_posts.province_id = ?", *q.ProvinceID)
	}

	if q.Search != "" {
		keyword := "%" + q.Search + "%"
		tx = tx.Where("(technician_posts.title LIKE ? OR technician_posts.description LIKE ?)", keyword, keyword)
	}

	if err := tx.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if err := tx.
		Preload("Service").
		Preload("Category").
		Preload("Province").
		Preload("Images", "deleted_at IS NULL").
		Order("technician_posts.created_at DESC").
		Limit(perPage).Offset((page - 1) * perPage).
		Find(&posts).Error; err != nil {
		return nil, 0, err
	}

	return posts, total, nil
}
