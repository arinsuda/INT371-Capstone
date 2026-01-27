package chat

import (
	apperrors "changsure-core-service/internal/errors"
	"github.com/gofiber/fiber/v3"
	"strconv"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) SendMessage(c fiber.Ctx) error {
	userID := c.Locals("userID").(uint)
	role := c.Locals("role").(string)

	roomIdStr := c.Params("roomId")
	bookingID, err := strconv.ParseUint(roomIdStr, 10, 32)
	if err != nil {
		return apperrors.BadRequest(c, "Invalid room ID format")
	}

	var req SendMessageReq
	if err := c.Bind().Body(&req); err != nil {
		return apperrors.BadRequest(c, "Invalid request body")
	}

	req.BookingID = uint(bookingID)

	msg, err := h.service.SendMessage(c.Context(), userID, role, req)
	if err != nil {
		return apperrors.HandleError(c, err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"message": "Message sent successfully",
		"data":    msg,
	})
}

func (h *Handler) GetChatRoomMessages(c fiber.Ctx) error {
	userID := c.Locals("userID").(uint)
	bookingIDStr := c.Params("roomId")

	bookingID, err := strconv.ParseUint(bookingIDStr, 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid booking ID"})
	}

	msgs, err := h.service.GetChatHistory(c.Context(), userID, uint(bookingID))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Successfully retrieved chat messages",
		"data":    msgs,
	})
}

func (h *Handler) GetChatRooms(c fiber.Ctx) error {
	userID := c.Locals("userID").(uint)
	role := c.Locals("role").(string)

	rooms, err := h.service.GetChatRooms(c.Context(), userID, role)
	if err != nil {

		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error": fiber.Map{
				"code":    "INTERNAL_SERVER_ERROR",
				"message": err.Error(),
			},
		})
	}

	if rooms == nil {
		rooms = []ChatRoomResponse{}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Successfully retrieved chat rooms",
		"data":    rooms,
	})
}
