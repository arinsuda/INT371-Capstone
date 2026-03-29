package technicianreview

import (
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
	storage storage.Storage
}

func NewHandler(service Service, st storage.Storage) *Handler {
	return &Handler{service: service, storage: st}
}

func (h *Handler) ListReviews(c fiber.Ctx) error {
	technicianID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	var q ListReviewsQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query params")
	}

	summary, err := h.service.GetSummary(c.Context(), technicianID)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	reviews, total, err := h.service.ListReviews(c.Context(), technicianID, q)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	reviewResponses := make([]ReviewItemResponse, 0, len(reviews))
	for _, r := range reviews {
		reviewResponses = append(reviewResponses, h.buildReviewItemResponse(c, r))
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"summary": summary,
			"reviews": reviewResponses,
		},
		"meta": fiber.Map{
			"total": total,
			"page":  q.Page,
			"limit": q.Limit,
		},
	})
}

func (h *Handler) buildReviewItemResponse(c fiber.Ctx, r booking.ReviewWithDetail) ReviewItemResponse {
	presign := func(key string) string {
		if h.storage == nil || key == "" {
			return key
		}
		if signed, err := h.storage.PresignGet(c.Context(), key, 24*time.Hour, false); err == nil {
			return signed
		}
		return key
	}

	var customerAvatar *string
	if r.CustomerAvatar != "" {
		signed := presign(r.CustomerAvatar)
		customerAvatar = &signed
	}

	var servicePicture *string
	if r.ServicePicture != "" {
		signed := presign(r.ServicePicture)
		servicePicture = &signed
	}

	images := make([]reviewImageResponse, 0, len(r.Images))
	for _, img := range r.Images {
		images = append(images, reviewImageResponse{
			ImageURL: presign(img.ImageURL),
		})
	}

	return ReviewItemResponse{
		ID:        r.ID,
		Rating:    r.Rating,
		Comment:   r.Comment,
		CreatedAt: r.CreatedAt,
		Customer: reviewCustomerResponse{
			ID:     r.CustomerID,
			Name:   r.CustomerName,
			Avatar: customerAvatar,
		},
		Service: reviewServiceResponse{
			ID:           r.ServiceID,
			Name:         r.ServiceName,
			Price:        r.ServicePrice,
			Picture:      servicePicture,
			CategoryID:   r.CategoryID,
			CategoryName: r.CategoryName,
		},
		Images: images,
	}
}
