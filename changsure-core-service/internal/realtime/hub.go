package realtime

import (
	"fmt"
	"sync"
)

type Hub struct {
	mu        sync.RWMutex
	techConns map[uint]map[*wsClient]struct{}
	custConns map[uint]map[*wsClient]struct{}
}

func NewHub() *Hub {
	return &Hub{
		techConns: make(map[uint]map[*wsClient]struct{}),
		custConns: make(map[uint]map[*wsClient]struct{}),
	}
}

func (h *Hub) AddTechnicianConn(technicianID uint, c *wsClient) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if h.techConns[technicianID] == nil {
		h.techConns[technicianID] = make(map[*wsClient]struct{})
	}
	h.techConns[technicianID][c] = struct{}{}
}

func (h *Hub) RemoveTechnicianConn(technicianID uint, c *wsClient) {
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

func (h *Hub) AddCustomerConn(customerID uint, c *wsClient) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.custConns[customerID] == nil {
		h.custConns[customerID] = make(map[*wsClient]struct{})
	}
	h.custConns[customerID][c] = struct{}{}
}

func (h *Hub) RemoveCustomerConn(customerID uint, c *wsClient) {
	h.mu.Lock()
	defer h.mu.Unlock()

	conns := h.custConns[customerID]
	if conns == nil {
		return
	}
	delete(conns, c)
	if len(conns) == 0 {
		delete(h.custConns, customerID)
	}
}

func (h *Hub) BroadcastToTechnician(technicianID uint, payload []byte) {
	h.mu.RLock()
	count := len(h.techConns[technicianID])
	h.mu.RUnlock()

	fmt.Printf("📡 BroadcastToTechnician: id=%d, connections=%d\n", technicianID, count)

	h.broadcast(h.techConns, technicianID, payload)
}

func (h *Hub) BroadcastToCustomer(customerID uint, payload []byte) {
	h.broadcast(h.custConns, customerID, payload)
}

func (h *Hub) BroadcastToAll(payload []byte) {
	h.mu.RLock()

	allPools := []map[uint]map[*wsClient]struct{}{h.techConns, h.custConns}
	h.mu.RUnlock()

	for _, pool := range allPools {
		h.mu.RLock()

		for id := range pool {
			h.mu.RUnlock()
			h.broadcast(pool, id, payload)
			h.mu.RLock()
		}
		h.mu.RUnlock()
	}
}

func (h *Hub) broadcast(pool map[uint]map[*wsClient]struct{}, id uint, payload []byte) {
	h.mu.RLock()
	connsMap := pool[id]

	conns := make([]*wsClient, 0, len(connsMap))
	for c := range connsMap {
		conns = append(conns, c)
	}
	h.mu.RUnlock()

	for _, c := range conns {
		select {
		case c.send <- payload:
		default:
			go h.forceClose(pool, id, c)
		}
	}
}

func (h *Hub) forceClose(pool map[uint]map[*wsClient]struct{}, id uint, c *wsClient) {
	_ = c.conn.Close()

	h.mu.Lock()
	defer h.mu.Unlock()
	conns := pool[id]
	if conns == nil {
		return
	}
	delete(conns, c)
	if len(conns) == 0 {
		delete(pool, id)
	}
}
