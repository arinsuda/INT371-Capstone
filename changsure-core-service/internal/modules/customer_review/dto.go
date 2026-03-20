package customerreview

import (
	"fmt"
	"time"
)

type CreateReviewRequest struct {
	Rating    int8     `json:"rating" form:"rating" validate:"required,min=1,max=5"`
	Comment   string   `json:"comment" form:"comment" validate:"omitempty,max=500"`
	ImageURLs []string `json:"image_urls" form:"-" validate:"omitempty,max=5"`
}

func (r *CreateReviewRequest) Validate() error {
	if r.Rating < 1 || r.Rating > 5 {
		return fmt.Errorf("rating must be between 1 and 5")
	}
	if len(r.ImageURLs) > 5 {
		return fmt.Errorf("maximum 5 images allowed")
	}
	return nil
}

type reviewImageResponse struct {
	ImageURL string `json:"image_url"`
}

type reviewCustomerResponse struct {
	ID     uint    `json:"id"`
	Name   string  `json:"name"`
	Avatar *string `json:"avatar"`
}

type reviewServiceResponse struct {
	ID           uint    `json:"id"`
	Name         string  `json:"name,omitempty"`
	Picture      *string `json:"picture"`
	CategoryID   uint    `json:"category_id,omitempty"`
	CategoryName string  `json:"category_name,omitempty"`
}

type CreateReviewResponse struct {
	ID        uint                   `json:"id"`
	Rating    int8                   `json:"rating"`
	Comment   string                 `json:"comment,omitempty"`
	CreatedAt time.Time              `json:"created_at"`
	Customer  reviewCustomerResponse `json:"customer"`
	Service   reviewServiceResponse  `json:"service"`
	Images    []reviewImageResponse  `json:"images"`
}
