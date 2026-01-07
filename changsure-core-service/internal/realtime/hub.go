package realtime

import (
	"sync"

	"github.com/gofiber/contrib/v3/websocket"
)

type Hub struct {
	mu sync.RWMutex

	techConns map[uint]map[*websocket.Conn]struct{}
}

func NewHub() *Hub {
	return &Hub{
		techConns: make(map[uint]map[*websocket.Conn]struct{}),
	}
}

func (h *Hub) AddTechnicianConn(technicianID uint, c *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if h.techConns[technicianID] == nil {
		h.techConns[technicianID] = make(map[*websocket.Conn]struct{})
	}
	h.techConns[technicianID][c] = struct{}{}
}

func (h *Hub) RemoveTechnicianConn(technicianID uint, c *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()

	conns := h.techConns[technicianID]
	if conns == nil {
		return
	}

	delete(conns, c)

	if len(conns) == 0 {
		delete(h.techConns, technicianID)
	}
}

func (h *Hub) BroadcastToTechnician(technicianID uint, payload []byte) {
	h.mu.RLock()
	conns := h.techConns[technicianID]
	h.mu.RUnlock()

	for c := range conns {

		_ = c.WriteMessage(websocket.TextMessage, payload)
	}
}
