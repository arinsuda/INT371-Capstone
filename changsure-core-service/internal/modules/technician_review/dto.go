package technicianreview

import "time"

type ListReviewsQuery struct {
	Page        int    `query:"page"`
	Limit       int    `query:"limit"`
	Rating      *int8  `query:"rating"`
	HasImages   string `query:"has_images"`
	ServiceType *uint  `query:"service_type"`
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
	Price        string  `json:"price,omitempty"`
	Picture      *string `json:"picture"`
	CategoryID   uint    `json:"category_id,omitempty"`
	CategoryName string  `json:"category_name,omitempty"`
}

type ReviewItemResponse struct {
	ID        uint                   `json:"id"`
	Rating    int8                   `json:"rating"`
	Comment   string                 `json:"comment,omitempty"`
	CreatedAt time.Time              `json:"created_at"`
	Customer  reviewCustomerResponse `json:"customer"`
	Service   reviewServiceResponse  `json:"service"`
	Images    []reviewImageResponse  `json:"images"`
}
