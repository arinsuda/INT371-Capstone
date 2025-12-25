package security

import (
	"github.com/gofiber/fiber/v3"
)

func CheckOwner(resourceOwnerID, requesterID uint) error {
	if requesterID == 0 {
		return fiber.NewError(401, "unauthorized")
	}
	if resourceOwnerID != requesterID {
		return fiber.NewError(403, "forbidden: not the owner")
	}
	return nil
}
