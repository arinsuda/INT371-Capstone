package technicianreview

import (
	"time"

	appErrors "changsure-core-service/internal/errors"
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

	if h.storage != nil {
		for i := range reviews {
			if reviews[i].CustomerAvatar != "" {
				if signed, err := h.storage.PresignGet(c.Context(), reviews[i].CustomerAvatar, 24*time.Hour, false); err == nil {
					reviews[i].CustomerAvatar = signed
				}
			}
			for j := range reviews[i].Images {
				key := reviews[i].Images[j].ImageURL
				if signed, err := h.storage.PresignGet(c.Context(), key, 24*time.Hour, false); err == nil {
					reviews[i].Images[j].ImageURL = signed
				}
			}
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"summary": summary,
			"reviews": reviews,
		},
		"meta": fiber.Map{
			"total": total,
			"page":  q.Page,
			"limit": q.Limit,
		},
	})
}
