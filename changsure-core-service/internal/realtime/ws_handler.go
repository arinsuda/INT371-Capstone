package realtime

import (
	"encoding/json"
	"strings"
	"sync"

	"github.com/gofiber/contrib/v3/websocket"
)

type WSHandler struct {
	hub *Hub

	verifyToken func(token string) (userID uint, role string, ok bool)
}

func NewWSHandler(hub *Hub, verifyFn func(string) (uint, string, bool)) *WSHandler {
	return &WSHandler{
		hub:         hub,
		verifyToken: verifyFn,
	}
}

func (h *WSHandler) TechnicianWS(c *websocket.Conn) {
	h.serveWS(c, "technician")
}

func (h *WSHandler) CustomerWS(c *websocket.Conn) {
	h.serveWS(c, "customer")
}

func (h *WSHandler) serveWS(c *websocket.Conn, requiredRole string) {
	token := extractToken(c)
	userID, role, ok := h.verifyToken(token)
	if !ok || userID == 0 || role != requiredRole {
		_ = c.WriteMessage(websocket.TextMessage, []byte(`{"type":"ERROR","message":"unauthorized"}`))
		_ = c.Close()
		return
	}

	client := newWSClient(c)

	if requiredRole == "technician" {
		h.hub.AddTechnicianConn(userID, client)
	} else {
		h.hub.AddCustomerConn(userID, client)
	}

	c.SetPongHandler(func(string) error { return nil })

	once := sync.Once{}
	cleanup := func() {
		once.Do(func() {
			if requiredRole == "technician" {
				h.hub.RemoveTechnicianConn(userID, client)
			} else {
				h.hub.RemoveCustomerConn(userID, client)
			}
			close(client.send)
			_ = c.Close()
		})
	}

	go client.writeLoop(cleanup)

	client.send <- []byte(`{"type":"CONNECTED"}`)

	for {
		if _, _, err := c.ReadMessage(); err != nil {
			break
		}
	}

	cleanup()
}

func MarshalEvent(eventType string, data any) []byte {
	b, _ := json.Marshal(map[string]any{
		"type": eventType,
		"data": data,
	})
	return b
}

func extractToken(c *websocket.Conn) string {
	if t := c.Query("token"); t != "" {
		t = strings.TrimSpace(t)
		return strings.TrimPrefix(t, "Bearer ")
	}
	if auth := c.Headers("Authorization"); auth != "" {
		auth = strings.TrimSpace(auth)
		return strings.TrimPrefix(auth, "Bearer ")
	}
	return ""
}
