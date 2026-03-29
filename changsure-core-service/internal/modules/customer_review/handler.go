package customerreview

import (
	"fmt"
	"path/filepath"
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
	storage storage.Storage
}

func NewHandler(service Service, st storage.Storage) *Handler {
	return &Handler{
		service: service,
		storage: st,
	}
}

func (h *Handler) CreateReview(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}
	if err := middleware.CheckOwnerOrAdmin(c, customerID); err != nil {
		return appErrors.HandleError(c, err)
	}

	bookingID, err := utils.ParseUintParam(c, "bookingID")
	if err != nil || bookingID == 0 {
		return appErrors.BadRequest(c, "invalid booking id")
	}

	var req CreateReviewRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request data")
	}

	form, err := c.MultipartForm()
	if err == nil && form != nil {
		files := form.File["images"]
		if len(files) > 5 {
			return appErrors.BadRequest(c, "maximum 5 images allowed")
		}

		for _, file := range files {
			fileData, err := file.Open()
			if err != nil {
				return appErrors.InternalError(c, "failed to open image file", err)
			}

			ext := filepath.Ext(file.Filename)
			filename := fmt.Sprintf("review_%d_%d%s", bookingID, time.Now().UnixNano(), ext)
			folder := fmt.Sprintf("reviews/%d", bookingID)

			key, uploadErr := h.storage.UploadFile(
				c.Context(),
				fileData,
				filename,
				folder,
				file.Size,
				file.Header.Get("Content-Type"),
			)
			fileData.Close()

			if uploadErr != nil {
				return appErrors.InternalError(c, "failed to upload image to storage", uploadErr)
			}

			req.ImageURLs = append(req.ImageURLs, key)
		}
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}
	if err := req.Validate(); err != nil {
		return appErrors.BadRequest(c, err.Error())
	}

	review, err := h.service.CreateReview(c.Context(), customerID, bookingID, req)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	resp := h.buildCreateReviewResponse(c, review)

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"message": "รีวิวสำเร็จ",
		"data":    resp,
	})
}

func (h *Handler) buildCreateReviewResponse(c fiber.Ctx, review *booking.Review) CreateReviewResponse {
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
	if review.CustomerAvatar != "" {
		signed := presign(review.CustomerAvatar)
		customerAvatar = &signed
	}

	var servicePicture *string
	if review.ServicePicture != "" {
		signed := presign(review.ServicePicture)
		servicePicture = &signed
	}

	images := make([]reviewImageResponse, 0, len(review.Images))
	for _, img := range review.Images {
		images = append(images, reviewImageResponse{
			ImageURL: presign(img.ImageURL),
		})
	}

	return CreateReviewResponse{
		ID:        review.ID,
		Rating:    review.Rating,
		Comment:   review.Comment,
		CreatedAt: review.CreatedAt,
		Customer: reviewCustomerResponse{
			ID:     review.CustomerID,
			Name:   review.CustomerName,
			Avatar: customerAvatar,
		},
		Service: reviewServiceResponse{
			ID:           review.ServiceID,
			Name:         review.ServiceName,
			Picture:      servicePicture,
			CategoryID:   review.CategoryID,
			CategoryName: review.CategoryName,
		},
		Images: images,
	}
}
