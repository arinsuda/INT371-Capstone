package realtime

import (
	"encoding/json"

	"github.com/gofiber/contrib/v3/websocket"
)

type WSHandler struct {
	hub *Hub

	verifyTechnicianToken func(token string) (technicianID uint, ok bool)
}

func NewWSHandler(hub *Hub, verifyFn func(string) (uint, bool)) *WSHandler {
	return &WSHandler{
		hub:                   hub,
		verifyTechnicianToken: verifyFn,
	}
}

func (h *WSHandler) TechnicianWS(c *websocket.Conn) {

	token := c.Query("token")
	techID, ok := h.verifyTechnicianToken(token)

	if !ok || techID == 0 {

		_ = c.WriteMessage(websocket.TextMessage, []byte(`{"type":"ERROR","message":"unauthorized"}`))
		_ = c.Close()
		return
	}

	h.hub.AddTechnicianConn(techID, c)

	defer h.hub.RemoveTechnicianConn(techID, c)

	_ = c.WriteMessage(websocket.TextMessage, []byte(`{"type":"CONNECTED"}`))

	for {
		_, msg, err := c.ReadMessage()
		if err != nil {
			break
		}

		_ = msg
	}
}

func MarshalEvent(eventType string, data any) []byte {
	b, _ := json.Marshal(map[string]any{
		"type": eventType,
		"data": data,
	})
	return b
}