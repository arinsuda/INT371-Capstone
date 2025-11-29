package technician_works

import (
	"context"
	"errors"

	"changsure-core-service/pkg/storage"
	"time"
)

var (
	ErrNotFound = errors.New("technician work not found")
)

type Service interface {
	Create(ctx context.Context, technicianID uint, dto CreateTechnicianWorkDTO) (*TechnicianWorkResponse, error)
	Update(ctx context.Context, technicianID, workID uint, dto UpdateTechnicianWorkDTO) (*TechnicianWorkResponse, error)
	Get(ctx context.Context, technicianID, workID uint) (*TechnicianWorkResponse, error)
	List(ctx context.Context, technicianID uint, q ListTechnicianWorksQuery) ([]TechnicianWorkResponse, int64, error)
	Delete(ctx context.Context, technicianID, workID uint, hard bool) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) Create(ctx context.Context, technicianID uint, dto CreateTechnicianWorkDTO) (*TechnicianWorkResponse, error) {
	if technicianID == 0 {
		return nil, errors.New("technician id is required")
	}

	work := &TechnicianWork{
		TechnicianID: technicianID,
		Title:        dto.Title,
		Description:  dto.Description,
		ServiceID:    dto.ServiceID,
		ProvinceID:   dto.ProvinceID,
		WorkDate:     dto.WorkDate,
		IsPublished:  true,
	}

	images := make([]TechnicianWorkImage, 0, len(dto.ImageURLs))
	for i, u := range dto.ImageURLs {
		if u == "" {
			continue
		}
		images = append(images, TechnicianWorkImage{
			ImageURL:  u,
			SortOrder: i,
		})
	}

	if err := s.repo.Create(ctx, work, images); err != nil {
		return nil, err
	}

	w, err := s.repo.FindByID(ctx, work.ID, technicianID)
	if err != nil {
		return nil, err
	}
	res := mapToResponse(w)
	return &res, nil
}

func (s *service) Update(ctx context.Context, technicianID, workID uint, dto UpdateTechnicianWorkDTO) (*TechnicianWorkResponse, error) {
	if technicianID == 0 {
		return nil, errors.New("technician id is required")
	}
	if workID == 0 {
		return nil, errors.New("work id is required")
	}

	w, err := s.repo.FindByID(ctx, workID, technicianID)
	if err != nil {
		return nil, err
	}

	if dto.Title != nil {
		w.Title = *dto.Title
	}
	if dto.Description != nil {
		w.Description = dto.Description
	}
	if dto.ServiceID != nil {
		w.ServiceID = dto.ServiceID
	}
	if dto.ProvinceID != nil {
		w.ProvinceID = dto.ProvinceID
	}
	if dto.WorkDate != nil {
		w.WorkDate = dto.WorkDate
	}
	if dto.IsPublished != nil {
		w.IsPublished = *dto.IsPublished
	}

	var newImages *[]TechnicianWorkImage
	if dto.ImageURLs != nil {
		imgs := make([]TechnicianWorkImage, 0, len(*dto.ImageURLs))
		for i, u := range *dto.ImageURLs {
			if u == "" {
				continue
			}
			imgs = append(imgs, TechnicianWorkImage{
				ImageURL:  u,
				SortOrder: i,
			})
		}
		newImages = &imgs
	}

	if err := s.repo.Update(ctx, w, newImages); err != nil {
		return nil, err
	}

	w2, err := s.repo.FindByID(ctx, workID, technicianID)
	if err != nil {
		return nil, err
	}

	res := mapToResponse(w2)
	return &res, nil
}

func (s *service) Get(ctx context.Context, technicianID, workID uint) (*TechnicianWorkResponse, error) {
	if technicianID == 0 || workID == 0 {
		return nil, errors.New("technician id and work id are required")
	}
	w, err := s.repo.FindByID(ctx, workID, technicianID)
	if err != nil {
		return nil, err
	}
	res := mapToResponse(w)
	return &res, nil
}

func (s *service) List(ctx context.Context, technicianID uint, q ListTechnicianWorksQuery) ([]TechnicianWorkResponse, int64, error) {
	if technicianID == 0 {
		return nil, 0, errors.New("technician id is required")
	}
	page := q.Page
	if page <= 0 {
		page = 1
	}
	perPage := q.PerPage
	if perPage <= 0 || perPage > 100 {
		perPage = 10
	}

	items, total, err := s.repo.ListByTechnician(ctx, technicianID, q, page, perPage)
	if err != nil {
		return nil, 0, err
	}

	res := make([]TechnicianWorkResponse, 0, len(items))
	for i := range items {
		res = append(res, mapToResponse(&items[i]))
	}
	return res, total, nil
}

func (s *service) Delete(ctx context.Context, technicianID, workID uint, hard bool) error {
	if technicianID == 0 || workID == 0 {
		return errors.New("technician id and work id are required")
	}
	if hard {
		return s.repo.HardDelete(ctx, workID, technicianID)
	}
	return s.repo.SoftDelete(ctx, workID, technicianID)
}

func mapToResponse(w *TechnicianWork) TechnicianWorkResponse {
	var (
		sid   *uint
		sname *string
		pid   *uint
		pname *string
	)

	if w.ServiceID != nil {
		sid = w.ServiceID
	}
	if w.Service != nil {
		n := w.Service.SerName
		sname = &n
	}
	if w.ProvinceID != nil {
		pid = w.ProvinceID
	}
	if w.Province != nil {
		n := w.Province.NameTH
		pname = &n
	}

	imgs := make([]TechnicianWorkImageResponse, 0, len(w.Images))
	for _, im := range w.Images {

		url := ""
		if im.ImageURL != "" && storage.GlobalMinio != nil {

			url = storage.GlobalMinio.PublicURL(im.ImageURL)

			if url == "" {
				p, err := storage.GlobalMinio.PresignGet(
					context.Background(),
					im.ImageURL,
					time.Hour,
					false,
				)
				if err == nil {
					url = p
				}
			}
		}

		imgs = append(imgs, TechnicianWorkImageResponse{
			ID:       im.ID,
			ImageURL: url,
			Order:    im.SortOrder,
		})
	}

	return TechnicianWorkResponse{
		ID:           w.ID,
		TechnicianID: w.TechnicianID,
		Title:        w.Title,
		Description:  w.Description,
		ServiceID:    sid,
		ServiceName:  sname,
		ProvinceID:   pid,
		ProvinceName: pname,
		WorkDate:     w.WorkDate,
		Images:       imgs,
		IsPublished:  w.IsPublished,
		CreatedAt:    w.CreatedAt.Unix(),
	}
}
