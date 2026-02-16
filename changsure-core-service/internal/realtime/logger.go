package realtime

import (
	"encoding/json"
	"fmt"
	"time"
)

type EventLogger struct {
	enabled bool
}

func NewEventLogger(enabled bool) *EventLogger {
	return &EventLogger{enabled: enabled}
}

func (l *EventLogger) LogEvent(eventType string, data map[string]any, userID uint, role string) {
	if !l.enabled {
		return
	}

	dataJSON, _ := json.Marshal(data)
	dataStr := string(dataJSON)
	if len(dataStr) > 200 {
		dataStr = dataStr[:200] + "..."
	}

	fmt.Printf("🔔 [%s] Event: %s | User: %d (%s) | Data: %s\n",
		time.Now().Format("15:04:05"),
		eventType,
		userID,
		role,
		dataStr,
	)
}

func (l *EventLogger) LogError(context string, err error, userID uint, role string) {
	fmt.Printf("❌ [%s] Error in %s | User: %d (%s) | Error: %v\n",
		time.Now().Format("15:04:05"),
		context,
		userID,
		role,
		err,
	)
}
