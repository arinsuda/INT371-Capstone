package technicianposts

import (
	"context"
	"errors"
)

var ErrNotFound = errors.New("post not found")

type Service interface {
	Create(ctx context.Context, techID uint, dto CreateTechnicianPostDTO) (*TechnicianPostResponse, error)
	Update(ctx context.Context, techID, postID uint, dto UpdateTechnicianPostDTO) (*TechnicianPostResponse, error)
	Get(ctx context.Context, techID, postID uint) (*TechnicianPostResponse, error)
	List(ctx context.Context, techID uint, q ListTechnicianPostsQuery) ([]TechnicianPostResponse, int64, error)
	Delete(ctx context.Context, techID, postID uint, hard bool) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) Create(ctx context.Context, techID uint, dto CreateTechnicianPostDTO) (*TechnicianPostResponse, error) {
	p := &TechnicianPost{
		TechnicianID: techID,
		Title:        dto.Title,
		Description:  dto.Description,
		ServiceID:    dto.ServiceID,
		ProvinceID:   dto.ProvinceID,
		PostDate:     dto.PostDate,
		IsPublished:  true,
	}

	imgs := make([]TechnicianPostImage, 0, len(dto.ImageURLs))
	for i, u := range dto.ImageURLs {
		if u == "" {
			continue
		}
		imgs = append(imgs, TechnicianPostImage{
			ImageURL:  u,
			SortOrder: i,
		})
	}

	if err := s.repo.Create(ctx, p, imgs); err != nil {
		return nil, err
	}

	p2, err := s.repo.FindByID(ctx, p.ID, techID)
	if err != nil {
		return nil, err
	}

	res := mapToResponse(p2)
	return &res, nil
}

func (s *service) Update(ctx context.Context, techID, postID uint, dto UpdateTechnicianPostDTO) (*TechnicianPostResponse, error) {
	p, err := s.repo.FindByID(ctx, postID, techID)
	if err != nil {
		return nil, ErrNotFound
	}

	if dto.Title != nil {
		p.Title = *dto.Title
	}
	if dto.Description != nil {
		p.Description = dto.Description
	}
	if dto.ServiceID != nil {
		p.ServiceID = dto.ServiceID
	}
	if dto.ProvinceID != nil {
		p.ProvinceID = dto.ProvinceID
	}
	if dto.PostDate != nil {
		p.PostDate = dto.PostDate
	}
	if dto.IsPublished != nil {
		p.IsPublished = *dto.IsPublished
	}

	var newImages *[]TechnicianPostImage
	if dto.ImageURLs != nil {
		imgs := make([]TechnicianPostImage, 0)
		for i, u := range *dto.ImageURLs {
			if u == "" {
				continue
			}
			imgs = append(imgs, TechnicianPostImage{
				ImageURL:  u,
				SortOrder: i,
			})
		}
		newImages = &imgs
	}

	if err := s.repo.Update(ctx, p, newImages); err != nil {
		return nil, err
	}

	p2, err := s.repo.FindByID(ctx, postID, techID)
	if err != nil {
		return nil, err
	}

	res := mapToResponse(p2)
	return &res, nil
}

func (s *service) Get(ctx context.Context, techID, postID uint) (*TechnicianPostResponse, error) {
	p, err := s.repo.FindByID(ctx, postID, techID)
	if err != nil {
		return nil, ErrNotFound
	}

	res := mapToResponse(p)
	return &res, nil
}

func (s *service) List(ctx context.Context, techID uint, q ListTechnicianPostsQuery) ([]TechnicianPostResponse, int64, error) {
	page := q.Page
	if page <= 0 {
		page = 1
	}
	perPage := q.PerPage
	if perPage <= 0 || perPage > 100 {
		perPage = 10
	}

	posts, total, err := s.repo.ListByTechnician(ctx, techID, q, page, perPage)
	if err != nil {
		return nil, 0, err
	}

	res := make([]TechnicianPostResponse, 0, len(posts))
	for i := range posts {
		res = append(res, mapToResponse(&posts[i]))
	}

	return res, total, nil
}

func (s *service) Delete(ctx context.Context, techID, postID uint, hard bool) error {
	if hard {
		return s.repo.HardDelete(ctx, postID, techID)
	}
	return s.repo.SoftDelete(ctx, postID, techID)
}
