package chat

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router) {

	chats := r.Group("/chat-rooms")
	chats.Get("/", h.GetChatRooms)
	chats.Get("/:roomID", h.GetChatRoomMessages)
	chats.Post("/:roomID/messages", h.SendMessage)
	chats.Patch("/:roomID", h.UpdateRoom)
	chats.Patch("/:roomID/messages", h.UpdateMessages)
}