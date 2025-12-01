package utils

import (
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v3"
)

func ParseUintParam(c fiber.Ctx, key string) (uint, error) {
	idStr := c.Params(key)
	id64, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		return 0, err
	}
	return uint(id64), nil
}

func QueryBool(c fiber.Ctx, key string, def bool) bool {
	raw := c.Query(key)
	if raw == "" {
		return def
	}
	b, err := strconv.ParseBool(raw)
	if err != nil {
		return def
	}
	return b
}

func NormalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}
