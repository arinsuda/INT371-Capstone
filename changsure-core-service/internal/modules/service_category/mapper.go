package servicecategory

import (
	"context"
	"time"

	"changsure-core-service/pkg/storage"
)

type CategoryResponse struct {
	ID        uint      `json:"id"`
	CatName   string    `json:"cat_name"`
	CatDesc   *string   `json:"cat_desc"`
	IconURL   *string   `json:"icon_url"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func MapCategoryToResponse(c *ServiceCategory) CategoryResponse {
	var iconURL *string

	if c.IconURL != nil && *c.IconURL != "" {
		u, err := storage.GlobalMinio.PresignGet(
			context.Background(),
			*c.IconURL,
			time.Hour,
			false,
		)
		if err == nil {
			iconURL = &u
		} else {
			iconURL = c.IconURL
		}
	}

	return CategoryResponse{
		ID:        c.ID,
		CatName:   c.CatName,
		CatDesc:   c.CatDesc,
		IconURL:   iconURL,
		IsActive:  c.IsActive,
		CreatedAt: c.CreatedAt,
		UpdatedAt: c.UpdatedAt,
	}
}
