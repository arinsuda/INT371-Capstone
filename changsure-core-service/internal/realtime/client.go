package realtime

import (
	"sync"
	"sync/atomic"
	"time"

	"github.com/gofiber/contrib/v3/websocket"
)

type wsClient struct {
	conn *websocket.Conn
	send chan []byte

	writeMu sync.Mutex
	closed  uint32 // 0=open, 1=closed
}

func newWSClient(conn *websocket.Conn) *wsClient {
	return &wsClient{
		conn: conn,
		send: make(chan []byte, 64), // ปรับขนาดได้ตาม traffic
	}
}

func (c *wsClient) markClosed() bool {
	return atomic.CompareAndSwapUint32(&c.closed, 0, 1)
}

func (c *wsClient) isClosed() bool {
	return atomic.LoadUint32(&c.closed) == 1
}

// enqueue แบบไม่ block: ถ้าเต็มจะคืน false เพื่อให้ hub ไป force close
func (c *wsClient) enqueue(payload []byte) bool {
	if c.isClosed() {
		return false
	}
	select {
	case c.send <- payload:
		return true
	default:
		return false
	}
}

func (c *wsClient) writeLoop(onClose func()) {
	defer onClose()

	pingTicker := time.NewTicker(25 * time.Second)
	defer pingTicker.Stop()

	for {
		select {
		case msg, ok := <-c.send:
			if !ok {
				return
			}
			if err := c.safeWrite(websocket.TextMessage, msg); err != nil {
				return
			}
		case <-pingTicker.C:
			_ = c.safeWrite(websocket.PingMessage, []byte("ping"))
		}
	}
}

func (c *wsClient) safeWrite(mt int, payload []byte) error {
	c.writeMu.Lock()
	defer c.writeMu.Unlock()
	return c.conn.WriteMessage(mt, payload)
}

func (c *wsClient) closeWS(reason string) {
	if !c.markClosed() {
		return
	}

	// best effort close control frame
	_ = c.writeControlSafe(
		websocket.CloseMessage,
		websocket.FormatCloseMessage(websocket.CloseNormalClosure, reason),
		time.Now().Add(1*time.Second),
	)

	_ = c.conn.Close()
}

func (c *wsClient) writeControlSafe(mt int, payload []byte, deadline time.Time) error {
	c.writeMu.Lock()
	defer c.writeMu.Unlock()
	return c.conn.WriteControl(mt, payload, deadline)
}
