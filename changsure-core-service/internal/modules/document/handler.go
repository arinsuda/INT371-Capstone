package document

import (
	"strconv"

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
	slug := c.Params("slug")
	v, err := h.service.CreateVersion(slug, dto)
	if err != nil {
		return err
	}
	return c.Status(fiber.StatusCreated).JSON(v)
}

func (h *Handler) Publish(c fiber.Ctx) error {
	slug := c.Params("slug")
	locale := c.Query("locale", "th")

	version, err := strconv.Atoi(c.Params("version"))
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid version")
	}

	if err := h.service.Publish(slug, version, locale); err != nil {
		return err
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *Handler) GetPublished(c fiber.Ctx) error {
	slug := c.Params("slug")
	locale := c.Query("locale", "th")

	res, err := h.service.GetPublished(slug, locale)
	if err != nil {
		return err
	}
	return c.JSON(res)
}

func (h *Handler) Accept(c fiber.Ctx) error {
	var dto AcceptDTO
	if err := c.Bind().Body(&dto); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}
	locale := c.Query("locale", "th")
	a, err := h.service.Accept(c.Params("slug"), dto.UserID, dto.Role, locale)
	if err != nil {
		return err
	}
	return c.Status(fiber.StatusCreated).JSON(a)
}
