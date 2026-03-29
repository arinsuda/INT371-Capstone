package technicianposts

import (
	"context"
	"time"

	"changsure-core-service/pkg/storage"
)

const imagePresignTTL = time.Hour

type Mapper struct {
	storage storage.Storage
}

func NewMapper(s storage.Storage) *Mapper {
	return &Mapper{storage: s}
}

func (m *Mapper) ToPostResponse(post *TechnicianPost) *TechnicianPostResponse {
	if post == nil {
		return nil
	}

	resp := &TechnicianPostResponse{
		ID:           post.ID,
		TechnicianID: post.TechnicianID,
		Title:        post.Title,
		Description:  post.Description,
		ServiceID:    post.ServiceID,
		ProvinceID:   post.ProvinceID,
		CategoryID:   post.ServiceCategoryID,
		IsPublished:  post.IsPublished,
		CreatedAt:    post.CreatedAt.Unix(),
	}

	if post.Service != nil {
		resp.ServiceName = &post.Service.SerName
	}
	if post.Category != nil {
		name := post.Category.CatName
		resp.CategoryName = &name
	}
	if post.Province != nil {
		resp.ProvinceName = &post.Province.NameTH
	}

	resp.Images = m.mapImages(post.Images)
	return resp
}

func (m *Mapper) mapImages(images []TechnicianPostImage) []TechnicianPostImageResponse {
	result := make([]TechnicianPostImageResponse, 0, len(images))
	for _, img := range images {
		result = append(result, TechnicianPostImageResponse{
			ID:       img.ID,
			ImageURL: m.presignURL(img.ImageURL),
			Order:    img.SortOrder,
		})
	}
	return result
}

func (m *Mapper) presignURL(key string) string {
	if key == "" {
		return ""
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	signed, err := m.storage.PresignGet(ctx, key, imagePresignTTL, false)
	if err != nil {
		return key
	}
	return signed
}
