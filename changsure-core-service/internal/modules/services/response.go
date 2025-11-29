package services

import (
	"changsure-core-service/pkg/storage"
	"time"
)

func MapServiceToResponse(m *Service) ServiceResponse {
	resp := ServiceResponse{
		ID:              m.ID,
		SerName:         m.SerName,
		SerDescription:  m.SerDescription,
		SerDetails:      m.SerDetails,
		AdditionalTerms: m.AdditionalTerms,
		WorkingDuration: m.WorkingDuration,
		DefaultPrice:    m.DefaultPrice,
		IsActive:        m.IsActive,
		CategoryID:      m.CategoryID,
		CreatedAt:       m.CreatedAt.Format(time.RFC3339),
		UpdatedAt:       m.UpdatedAt.Format(time.RFC3339),
	}

	if m.Category != nil {
		resp.CategoryName = &m.Category.CatName
	}

	imgs := make([]string, 0, len(m.ImageURLs))
	for _, key := range m.ImageURLs {
		if key == "" {
			continue
		}
		imgs = append(imgs, storage.GlobalMinio.PublicURL(key))
	}
	resp.ImageURLs = imgs

	resp.ImageURLs = imgs

	return resp
}
