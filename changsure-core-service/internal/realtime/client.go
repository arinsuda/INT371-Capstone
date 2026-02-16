package realtime

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gofiber/contrib/v3/websocket"
)

type wsClient struct {
	conn *websocket.Conn
	send chan []byte

	writeMu sync.Mutex
	closed  uint32
}

func newWSClient(conn *websocket.Conn) *wsClient {
	return &wsClient{
		conn: conn,
		send: make(chan []byte, 64),
	}
}

func (c *wsClient) markClosed() bool {
	return atomic.CompareAndSwapUint32(&c.closed, 0, 1)
}

func (c *wsClient) isClosed() bool {
	return atomic.LoadUint32(&c.closed) == 1
}

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

	pongReceived := make(chan bool, 1)
	pongTimeout := time.NewTimer(35 * time.Second)
	defer pongTimeout.Stop()

	c.conn.SetPongHandler(func(string) error {
		select {
		case pongReceived <- true:
		default:
		}
		return nil
	})

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

			if err := c.safeWrite(websocket.PingMessage, []byte("ping")); err != nil {
				return
			}

			if !pongTimeout.Stop() {
				select {
				case <-pongTimeout.C:
				default:
				}
			}
			pongTimeout.Reset(35 * time.Second)

		case <-pongReceived:

			if !pongTimeout.Stop() {
				select {
				case <-pongTimeout.C:
				default:
				}
			}
			pongTimeout.Reset(35 * time.Second)

		case <-pongTimeout.C:

			fmt.Println("⚠️ WebSocket: No pong received, closing connection")
			return
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
