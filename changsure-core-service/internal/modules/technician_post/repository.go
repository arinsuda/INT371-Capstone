package technicianposts

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	DB() *gorm.DB

	GetPost(ctx context.Context, postID, technicianID uint) (*TechnicianPost, error)
	CreatePost(ctx context.Context, post *TechnicianPost) error

	AddPostImages(ctx context.Context, images []TechnicianPostImage) error
	RemovePostImagesByID(ctx context.Context, postID uint, imageIDs []uint) error

	ListPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery) ([]TechnicianPost, int64, error)
	ListPublicPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery) ([]TechnicianPost, int64, error)
	GetPublicPost(ctx context.Context, postID, technicianID uint) (*TechnicianPost, error)

	SoftDeletePost(ctx context.Context, postID, technicianID uint) error
	HardDeletePost(ctx context.Context, postID, technicianID uint) error

	// Report
	CreateReport(ctx context.Context, report *TechnicianPostReport) error
	CountWarningsByTechnician(ctx context.Context, technicianID uint) (int64, error)
	ListReportsByTechnician(ctx context.Context, technicianID uint, q ListPostReportsQuery) ([]TechnicianPostReport, int64, error)
	ExistsReportByAdminAndPost(ctx context.Context, adminID, postID uint) (bool, error)
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) DB() *gorm.DB { return r.db }

func withPostPreloads(tx *gorm.DB) *gorm.DB {
	return tx.
		Preload("Service").
		Preload("Category").
		Preload("Province").
		Preload("Images", "deleted_at IS NULL")
}

func (r *repository) buildPostQuery(
	ctx context.Context,
	techID uint,
	q ListTechnicianPostsQuery,
	publishedOnly bool,
) *gorm.DB {
	tx := r.db.WithContext(ctx).
		Model(&TechnicianPost{}).
		Where("technician_posts.technician_id = ? AND technician_posts.deleted_at IS NULL", techID)

	if publishedOnly {
		tx = tx.Where("technician_posts.is_published = ?", true)
	} else if q.IsPublished != nil {
		tx = tx.Where("technician_posts.is_published = ?", *q.IsPublished)
	}

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
		kw := "%" + q.Search + "%"
		tx = tx.Where("(technician_posts.title LIKE ? OR technician_posts.description LIKE ?)", kw, kw)
	}

	return tx
}

func (r *repository) paginatedFind(tx *gorm.DB, q ListTechnicianPostsQuery) ([]TechnicianPost, int64, error) {
	var total int64
	if err := tx.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var posts []TechnicianPost
	err := withPostPreloads(tx).
		Order("technician_posts.created_at DESC").
		Limit(q.PerPage).
		Offset((q.Page - 1) * q.PerPage).
		Find(&posts).Error

	return posts, total, err
}

func (r *repository) GetPost(ctx context.Context, postID, technicianID uint) (*TechnicianPost, error) {
	var post TechnicianPost
	err := withPostPreloads(r.db.WithContext(ctx)).
		Where("id = ? AND technician_id = ?", postID, technicianID).
		First(&post).Error
	if err != nil {
		return nil, err
	}
	return &post, nil
}

func (r *repository) ListPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery) ([]TechnicianPost, int64, error) {
	tx := r.buildPostQuery(ctx, techID, q, false)
	return r.paginatedFind(tx, q)
}

func (r *repository) ListPublicPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery) ([]TechnicianPost, int64, error) {
	tx := r.buildPostQuery(ctx, techID, q, true)
	return r.paginatedFind(tx, q)
}

func (r *repository) GetPublicPost(ctx context.Context, postID, technicianID uint) (*TechnicianPost, error) {
	var post TechnicianPost
	err := withPostPreloads(r.db.WithContext(ctx)).
		Where("id = ? AND technician_id = ? AND is_published = ? AND deleted_at IS NULL", postID, technicianID, true).
		First(&post).Error
	if err != nil {
		return nil, err
	}
	return &post, nil
}

func (r *repository) CreatePost(ctx context.Context, post *TechnicianPost) error {
	return r.db.WithContext(ctx).Create(post).Error
}

func (r *repository) AddPostImages(ctx context.Context, images []TechnicianPostImage) error {
	if len(images) == 0 {
		return nil
	}
	return r.db.WithContext(ctx).Create(&images).Error
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
		if err := tx.Unscoped().Where("post_id = ?", postID).Delete(&TechnicianPostImage{}).Error; err != nil {
			return err
		}
		return tx.Unscoped().
			Where("id = ? AND technician_id = ?", postID, technicianID).
			Delete(&TechnicianPost{}).Error
	})
}

// --- Report ---

func (r *repository) CreateReport(ctx context.Context, report *TechnicianPostReport) error {
	return r.db.WithContext(ctx).Create(report).Error
}

func (r *repository) CountWarningsByTechnician(ctx context.Context, technicianID uint) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&TechnicianPostReport{}).
		Where("technician_id = ? AND severity = ?", technicianID, ReportSeverityWarning).
		Count(&count).Error
	return count, err
}

func (r *repository) ListReportsByTechnician(ctx context.Context, technicianID uint, q ListPostReportsQuery) ([]TechnicianPostReport, int64, error) {
	tx := r.db.WithContext(ctx).
		Model(&TechnicianPostReport{}).
		Where("technician_id = ?", technicianID)

	var total int64
	if err := tx.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var reports []TechnicianPostReport
	err := tx.
		Preload("Post").
		Preload("Admin").
		Order("created_at DESC").
		Limit(q.PerPage).
		Offset((q.Page - 1) * q.PerPage).
		Find(&reports).Error

	return reports, total, err
}

func (r *repository) ExistsReportByAdminAndPost(ctx context.Context, adminID, postID uint) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&TechnicianPostReport{}).
		Where("admin_id = ? AND post_id = ?", adminID, postID).
		Count(&count).Error
	return count > 0, err
}
