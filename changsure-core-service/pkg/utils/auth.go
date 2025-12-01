package utils

import (
	"github.com/gofiber/fiber/v3"
	"strconv"
)

func GetUserIDFromToken(c fiber.Ctx) uint {
	if v := c.Locals("userID"); v != nil {
		switch x := v.(type) {

		case uint:
			return x

		case uint64:
			return uint(x)

		case int:
			if x > 0 {
				return uint(x)
			}

		case string:
			if id, err := strconv.ParseUint(x, 10, 64); err == nil {
				return uint(id)
			}
		}
	}

	return 0
}
