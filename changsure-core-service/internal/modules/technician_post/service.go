package technicianposts

import (
	"context"
	"fmt"
	"log/slog"
	"mime/multipart"
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/pkg/storage"

	"gorm.io/gorm"
)

type Service interface {
	Create(ctx context.Context, techID uint, req CreateTechnicianPostDTO) (*TechnicianPostResponse, error)
	Update(ctx context.Context, techID, postID uint, req UpdateTechnicianPostDTO) (*TechnicianPostResponse, error)
	Delete(ctx context.Context, techID, postID uint, hard bool) error
	Get(ctx context.Context, techID, postID uint) (*TechnicianPostResponse, error)
	List(ctx context.Context, techID uint, q ListTechnicianPostsQuery) (*PostListResponse, error)
	ListPublicPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery) (*PostListResponse, error)
	GetPublic(ctx context.Context, techID, postID uint) (*TechnicianPostResponse, error)
}

type service struct {
	repo    Repository
	storage storage.Storage
	mapper  *Mapper
}

func NewService(repo Repository, s storage.Storage) Service {
	return &service{
		repo:    repo,
		storage: s,
		mapper:  NewMapper(s),
	}
}

func (s *service) Get(ctx context.Context, techID, postID uint) (*TechnicianPostResponse, error) {
	post, err := s.repo.GetPost(ctx, postID, techID)
	if err != nil {
		return nil, appErrors.NewNotFound("post not found")
	}
	return s.mapper.ToPostResponse(post), nil
}

func (s *service) List(ctx context.Context, techID uint, q ListTechnicianPostsQuery) (*PostListResponse, error) {
	q.SetDefaults()
	posts, total, err := s.repo.ListPosts(ctx, techID, q)
	if err != nil {
		return nil, fmt.Errorf("list posts: %w", err)
	}
	return s.toListResponse(posts, total, q), nil
}

func (s *service) ListPublicPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery) (*PostListResponse, error) {
	q.SetDefaults()
	posts, total, err := s.repo.ListPublicPosts(ctx, techID, q)
	if err != nil {
		return nil, fmt.Errorf("list public posts: %w", err)
	}
	return s.toListResponse(posts, total, q), nil
}

func (s *service) GetPublic(ctx context.Context, techID, postID uint) (*TechnicianPostResponse, error) {
	post, err := s.repo.GetPublicPost(ctx, postID, techID)
	if err != nil {
		return nil, appErrors.NewNotFound("post not found")
	}
	return s.mapper.ToPostResponse(post), nil
}

func (s *service) Create(ctx context.Context, techID uint, req CreateTechnicianPostDTO) (*TechnicianPostResponse, error) {
	post := &TechnicianPost{
		TechnicianID:      techID,
		Title:             req.Title,
		Description:       req.Description,
		ServiceCategoryID: req.ServiceCategoryID,
		IsPublished:       true,
	}

	if err := s.repo.CreatePost(ctx, post); err != nil {
		return nil, fmt.Errorf("create post: %w", err)
	}

	if len(req.Images) > 0 {
		imgs, err := s.uploadImages(ctx, post.ID, req.Images)
		if err != nil {
			return nil, err
		}
		if err := s.repo.AddPostImages(ctx, imgs); err != nil {
			return nil, fmt.Errorf("save images: %w", err)
		}
	}

	full, err := s.repo.GetPost(ctx, post.ID, techID)
	if err != nil {
		return nil, fmt.Errorf("reload post: %w", err)
	}
	return s.mapper.ToPostResponse(full), nil
}

func (s *service) Update(ctx context.Context, techID, postID uint, req UpdateTechnicianPostDTO) (*TechnicianPostResponse, error) {
	if _, err := s.repo.GetPost(ctx, postID, techID); err != nil {
		return nil, appErrors.NewNotFound("post not found")
	}

	var newImages []TechnicianPostImage
	if len(req.NewImages) > 0 {
		uploadCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
		defer cancel()

		imgs, err := s.uploadImages(uploadCtx, postID, req.NewImages)
		if err != nil {
			return nil, err
		}
		newImages = imgs
	}

	err := s.repo.DB().WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		updateData := buildUpdateMap(req)
		if len(updateData) > 0 {
			if err := tx.Model(&TechnicianPost{}).
				Where("id = ? AND technician_id = ?", postID, techID).
				Updates(updateData).Error; err != nil {
				return fmt.Errorf("update post fields: %w", err)
			}
		}

		if len(req.ImageIDsToDelete) > 0 {
			if err := tx.Where("post_id = ? AND id IN ?", postID, req.ImageIDsToDelete).
				Delete(&TechnicianPostImage{}).Error; err != nil {
				return fmt.Errorf("delete images: %w", err)
			}
		}

		if len(newImages) > 0 {
			if err := tx.Create(&newImages).Error; err != nil {
				return fmt.Errorf("insert images: %w", err)
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	full, err := s.repo.GetPost(ctx, postID, techID)
	if err != nil {
		return nil, fmt.Errorf("reload post: %w", err)
	}
	return s.mapper.ToPostResponse(full), nil
}

func (s *service) Delete(ctx context.Context, techID, postID uint, hard bool) error {
	if hard {
		return s.repo.HardDeletePost(ctx, postID, techID)
	}
	return s.repo.SoftDeletePost(ctx, postID, techID)
}

const (
	maxUploadRetries = 3
	retryBaseDelay   = 200 * time.Millisecond
)

func (s *service) uploadImages(ctx context.Context, postID uint, files []*multipart.FileHeader) ([]TechnicianPostImage, error) {
	images := make([]TechnicianPostImage, 0, len(files))

	for i, file := range files {
		key, err := s.uploadWithRetry(ctx, postID, file, maxUploadRetries)
		if err != nil {
			return nil, err
		}
		images = append(images, TechnicianPostImage{
			PostID:    postID,
			ImageURL:  key,
			SortOrder: i,
		})
	}

	return images, nil
}

func (s *service) uploadWithRetry(ctx context.Context, postID uint, file *multipart.FileHeader, maxRetry int) (string, error) {
	var lastErr error

	for attempt := 1; attempt <= maxRetry; attempt++ {
		src, err := file.Open()
		if err != nil {
			return "", fmt.Errorf("open file %q: %w", file.Filename, err)
		}

		filename := fmt.Sprintf("%d_%d_%s", postID, time.Now().UnixNano(), file.Filename)
		key, err := s.storage.UploadFile(
			ctx,
			src,
			filename,
			fmt.Sprintf("posts/%d", postID),
			file.Size,
			file.Header.Get("Content-Type"),
		)
		src.Close()

		if err == nil {
			return key, nil
		}

		lastErr = err
		slog.Warn("upload attempt failed",
			"attempt", attempt,
			"max", maxRetry,
			"file", file.Filename,
			"error", err,
		)
		time.Sleep(time.Duration(attempt) * retryBaseDelay)
	}

	return "", fmt.Errorf("upload %q failed after %d retries: %w", file.Filename, maxRetry, lastErr)
}

func buildUpdateMap(req UpdateTechnicianPostDTO) map[string]any {
	data := make(map[string]any)
	if req.Title != nil {
		data["title"] = *req.Title
	}
	if req.Description != nil {
		data["description"] = *req.Description
	}
	if req.ServiceCategoryID != nil {
		data["service_category_id"] = *req.ServiceCategoryID
	}
	if req.IsPublished != nil {
		data["is_published"] = *req.IsPublished
	}
	return data
}

func (s *service) toListResponse(posts []TechnicianPost, total int64, q ListTechnicianPostsQuery) *PostListResponse {
	items := make([]TechnicianPostResponse, 0, len(posts))
	for i := range posts {
		items = append(items, *s.mapper.ToPostResponse(&posts[i]))
	}
	return &PostListResponse{
		Items:   items,
		Total:   total,
		Page:    q.Page,
		PerPage: q.PerPage,
	}
}
