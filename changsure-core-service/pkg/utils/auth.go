package utils

import (
	"context"
	"strconv"

	"github.com/gofiber/fiber/v3"
)

// -------------------------------------------
// Get userID from Fiber context
// -------------------------------------------
func GetUserID(c fiber.Ctx) uint {
	v := c.Locals("userID")
	if v == nil {
		return 0
	}

	switch val := v.(type) {
	case uint:
		return val
	case uint64:
		return uint(val)
	case int:
		if val > 0 {
			return uint(val)
		}
	case string:
		n, err := strconv.ParseUint(val, 10, 64)
		if err == nil {
			return uint(n)
		}
	}
	return 0
}

// -------------------------------------------
// Context key for userID inside service layer
// -------------------------------------------
type userIDContextKey struct{}

// -------------------------------------------
// Inject userID → into context.Context
// (handler → service)
// -------------------------------------------
func InjectUserIDIntoContext(ctx context.Context, userID uint) context.Context {
	return context.WithValue(ctx, userIDContextKey{}, userID)
}

// -------------------------------------------
// Extract userID from context inside service
// -------------------------------------------
func GetUserIDFromContext(ctx context.Context) uint {
	v := ctx.Value(userIDContextKey{})
	if v == nil {
		return 0
	}
	id, ok := v.(uint)
	if !ok {
		return 0
	}
	return id
}
