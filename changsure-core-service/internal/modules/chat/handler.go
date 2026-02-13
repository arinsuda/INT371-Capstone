package chat

import (
	apperrors "changsure-core-service/internal/errors"
	"strconv"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) SendMessage(c fiber.Ctx) error {

	userID, ok := c.Locals("userID").(uint)
	if !ok {
		return apperrors.Unauthorized(c, "User not authenticated")
	}

	role, ok := c.Locals("role").(string)
	if !ok {
		return apperrors.Unauthorized(c, "User role not found")
	}

	bookingID, err := h.parseBookingID(c.Params("roomId"))
	if err != nil {
		return apperrors.BadRequest(c, "Invalid room ID format")
	}

	var req SendMessageReq
	if err := c.Bind().Body(&req); err != nil {
		return apperrors.BadRequest(c, "Invalid request body")
	}

	req.BookingID = bookingID

	file, _ := c.FormFile("file")

	msg, err := h.service.SendMessage(c.Context(), userID, role, req, file)
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

	userID, ok := c.Locals("userID").(uint)
	if !ok {
		return apperrors.Unauthorized(c, "User not authenticated")
	}

	bookingID, err := h.parseBookingID(c.Params("roomId"))
	if err != nil {
		return apperrors.BadRequest(c, "Invalid room ID format")
	}

	var query GetHistoryQuery
	if err := c.Bind().Query(&query); err != nil {
		return apperrors.BadRequest(c, "Invalid query parameters")
	}

	msgs, err := h.service.GetChatHistory(c.Context(), userID, bookingID, query)
	if err != nil {
		return apperrors.HandleError(c, err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Successfully retrieved chat messages",
		"data":    msgs,
	})
}

func (h *Handler) GetChatRooms(c fiber.Ctx) error {

	userID, ok := c.Locals("userID").(uint)
	if !ok {
		return apperrors.Unauthorized(c, "User not authenticated")
	}

	role, ok := c.Locals("role").(string)
	if !ok {
		return apperrors.Unauthorized(c, "User role not found")
	}

	statusFilter := c.Query("status", "")

	searchQuery := c.Query("search", "")

	rooms, err := h.service.GetChatRooms(c.Context(), userID, role, statusFilter, searchQuery)
	if err != nil {
		return apperrors.HandleError(c, err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Successfully retrieved chat rooms",
		"data":    rooms,
	})
}

func (h *Handler) MarkRoomAsRead(c fiber.Ctx) error {

	userID, ok := c.Locals("userID").(uint)
	if !ok {
		return apperrors.Unauthorized(c, "User not authenticated")
	}

	role, ok := c.Locals("role").(string)
	if !ok {
		return apperrors.Unauthorized(c, "User role not found")
	}

	bookingID, err := h.parseBookingID(c.Params("roomId"))
	if err != nil {
		return apperrors.BadRequest(c, "Invalid room ID format")
	}

	if err := h.service.MarkRoomAsRead(c.Context(), userID, role, bookingID); err != nil {
		return apperrors.HandleError(c, err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Room marked as read successfully",
	})
}

func (h *Handler) parseBookingID(idStr string) (uint, error) {
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		return 0, err
	}
	return uint(id), nil
}
