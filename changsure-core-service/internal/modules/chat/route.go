package chat

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router) {

	chats := r.Group("/chats")
	chats.Get("/rooms", h.GetChatRooms)
	chats.Get("/rooms/:roomId", h.GetChatRoomMessages)
	chats.Post("/rooms/:roomId/messages", h.SendMessage)
	chats.Post("/rooms/:roomId/read", h.MarkRoomAsRead)
}
