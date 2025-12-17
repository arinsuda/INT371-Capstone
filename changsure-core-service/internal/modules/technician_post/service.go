package technicianposts

import (
	"context"
	"errors"
	"fmt"
	"mime/multipart"
	"time"

	"gorm.io/gorm"

	"changsure-core-service/pkg/storage"
)

var (
	ErrPostNotFound = errors.New("post not found")
)

type Service interface {
	Create(ctx context.Context, techID uint, req CreateTechnicianPostDTO) (*TechnicianPostResponse, error)
	Update(ctx context.Context, techID uint, postID uint, req UpdateTechnicianPostDTO) (*TechnicianPostResponse, error)
	Delete(ctx context.Context, techID uint, postID uint, hard bool) error
	Get(ctx context.Context, techID uint, postID uint) (*TechnicianPostResponse, error)
	List(ctx context.Context, techID uint, q ListTechnicianPostsQuery) ([]TechnicianPostResponse, int64, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) Get(ctx context.Context, techID uint, postID uint) (*TechnicianPostResponse, error) {
	post, err := s.repo.GetPost(ctx, postID, techID)
	if err != nil {
		return nil, ErrPostNotFound
	}

	return ToPostResponse(post), nil
}

func (s *service) List(ctx context.Context, techID uint, q ListTechnicianPostsQuery) ([]TechnicianPostResponse, int64, error) {

	if q.Page < 1 {
		q.Page = 1
	}
	if q.PerPage < 1 || q.PerPage > 100 {
		q.PerPage = 20
	}

	posts, total, err := s.repo.ListPosts(ctx, techID, q, q.Page, q.PerPage)
	if err != nil {
		return nil, 0, err
	}

	resp := make([]TechnicianPostResponse, 0, len(posts))
	for _, p := range posts {
		resp = append(resp, *ToPostResponse(&p))
	}

	return resp, total, nil
}

func (s *service) Create(ctx context.Context, techID uint, req CreateTechnicianPostDTO) (*TechnicianPostResponse, error) {

	db := s.repo.DB()

	post := &TechnicianPost{
		TechnicianID: techID,
		Title:        req.Title,
		Description:  req.Description,
		ServiceID:    req.ServiceID,
		ProvinceID:   req.ProvinceID,
		IsPublished:  true,
	}

	err := db.Transaction(func(tx *gorm.DB) error {

		if err := s.repo.CreatePost(ctx, post); err != nil {
			return fmt.Errorf("failed to create post: %w", err)
		}

		if len(req.Images) > 0 {
			imgs, err := s.uploadAndBuildImages(ctx, tx, post.ID, req.Images)
			if err != nil {
				return err
			}

			if err := s.repo.AddPostImages(ctx, imgs); err != nil {
				return fmt.Errorf("failed to save images: %w", err)
			}
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	full, _ := s.repo.GetPost(ctx, post.ID, techID)
	return ToPostResponse(full), nil
}

func (s *service) Update(ctx context.Context, techID uint, postID uint, req UpdateTechnicianPostDTO) (*TechnicianPostResponse, error) {

	db := s.repo.DB()

	_, err := s.repo.GetPost(ctx, postID, techID)
	if err != nil {
		return nil, ErrPostNotFound
	}

	err = db.Transaction(func(tx *gorm.DB) error {

		updateData := map[string]any{}

		if req.Title != nil {
			updateData["title"] = *req.Title
		}
		if req.Description != nil {
			updateData["description"] = *req.Description
		}
		if req.ServiceID != nil {
			updateData["service_id"] = *req.ServiceID
		}
		if req.ProvinceID != nil {
			updateData["province_id"] = *req.ProvinceID
		}
		if req.IsPublished != nil {
			updateData["is_published"] = *req.IsPublished
		}

		if len(updateData) > 0 {
			if err := tx.Model(&TechnicianPost{}).
				Where("id = ? AND technician_id = ?", postID, techID).
				Updates(updateData).Error; err != nil {
				return fmt.Errorf("update post failed: %w", err)
			}
		}

		if len(req.ImageIDsToDelete) > 0 {
			if err := s.repo.RemovePostImagesByID(ctx, postID, req.ImageIDsToDelete); err != nil {
				return fmt.Errorf("failed to delete images: %w", err)
			}
		}

		if len(req.NewImages) > 0 {
			imgs, err := s.uploadAndBuildImages(ctx, tx, postID, req.NewImages)
			if err != nil {
				return err
			}

			if err := s.repo.AddPostImages(ctx, imgs); err != nil {
				return fmt.Errorf("failed to save new images: %w", err)
			}
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	full, _ := s.repo.GetPost(ctx, postID, techID)
	return ToPostResponse(full), nil
}

func (s *service) Delete(ctx context.Context, techID uint, postID uint, hard bool) error {
	if hard {

		return s.repo.HardDeletePost(ctx, postID, techID)
	}

	return s.repo.SoftDeletePost(ctx, postID, techID)
}

func (s *service) uploadAndBuildImages(
	ctx context.Context,
	tx *gorm.DB,
	postID uint,
	files []*multipart.FileHeader,
) ([]TechnicianPostImage, error) {

	var images []TechnicianPostImage

	for i, file := range files {

		src, err := file.Open()
		if err != nil {
			return nil, fmt.Errorf("failed to open file: %w", err)
		}
		defer src.Close()

		filename := fmt.Sprintf("%d_%d_%s", postID, time.Now().UnixNano(), file.Filename)

		key, err := storage.GlobalMinio.UploadFile(
			ctx,
			src,
			filename,
			fmt.Sprintf("posts/%d", postID),
			file.Size,
			file.Header.Get("Content-Type"),
		)
		if err != nil {
			return nil, fmt.Errorf("upload failed: %w", err)
		}

		images = append(images, TechnicianPostImage{
			PostID:    postID,
			ImageURL:  key,
			SortOrder: i,
		})
	}

	return images, nil
}
