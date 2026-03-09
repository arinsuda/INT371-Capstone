package document

import (
	"strconv"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{s}
}

func (h *Handler) CreateDocument(c fiber.Ctx) error {
	var dto CreateDocumentDTO
	if err := c.Bind().Body(&dto); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	doc, err := h.service.CreateDocument(dto)
	if err != nil {
		return err
	}
	return c.Status(fiber.StatusCreated).JSON(doc)
}

func (h *Handler) CreateVersion(c fiber.Ctx) error {
	var dto CreateVersionDTO
	if err := c.Bind().Body(&dto); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	v, err := h.service.CreateVersion(c.Params("slug"), dto)
	if err != nil {
		return err
	}
	return c.Status(fiber.StatusCreated).JSON(v)
}

func (h *Handler) Publish(c fiber.Ctx) error {
	version, err := strconv.Atoi(c.Params("version"))
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid version")
	}
	if err := h.service.Publish(c.Params("slug"), version, c.Query("locale", "th")); err != nil {
		return err
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *Handler) GetPublished(c fiber.Ctx) error {
	res, err := h.service.GetPublished(c.Params("slug"), c.Query("locale", "th"))
	if err != nil {
		return err
	}
	return c.JSON(res)
}

func (h *Handler) Accept(c fiber.Ctx) error {
	tokenUserID, ok := middleware.GetUserID(c)
	if !ok {
		return appErrors.Unauthorized(c, "unauthorized")
	}
	tokenRole, ok := middleware.GetRole(c)
	if !ok {
		return appErrors.Unauthorized(c, "role not found in token")
	}

	var dto AcceptDTO
	if err := c.Bind().Body(&dto); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if dto.UserID != tokenUserID {
		return appErrors.Forbidden(c, "you are not allowed to accept on behalf of another user")
	}

	if len(dto.Consents) == 0 {
		return appErrors.BadRequest(c, "consents are required")
	}

	a, err := h.service.Accept(c.Params("slug"), tokenUserID, tokenRole, c.Query("locale", "th"), dto.Consents)
	if err != nil {
		return err
	}
	return c.Status(fiber.StatusCreated).JSON(a)
}
