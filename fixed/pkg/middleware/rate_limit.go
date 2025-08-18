package middleware

import (
	"time"
	"strings"
	"fixed/utils"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/limiter"
)

func RateLimit() fiber.Handler {
	return limiter.New(limiter.Config{
		Max:        100, // 100 requests
		Expiration: 1 * time.Minute,
		KeyGenerator: func(c fiber.Ctx) string {
			return c.Get("X-Forwarded-For", c.IP())
		},
		LimitReached: func(c fiber.Ctx) error {
			return utils.ErrorResponse(c, fiber.StatusTooManyRequests, "Rate limit exceeded", nil)
		},
		SkipFailedRequests:     false,
		SkipSuccessfulRequests: false,
		LimiterMiddleware:      limiter.SlidingWindow{},
	})
}

func StrictRateLimit() fiber.Handler {
	return limiter.New(limiter.Config{
		Max:        30, // 30 requests per minute in production
		Expiration: 1 * time.Minute,
		KeyGenerator: func(c fiber.Ctx) string {
			// Use X-Forwarded-For for load balancer/proxy setups
			forwarded := c.Get("X-Forwarded-For")
			if forwarded != "" {
				// Get the first IP from X-Forwarded-For chain
				ips := strings.Split(forwarded, ",")
				return strings.TrimSpace(ips[0])
			}
			return c.IP()
		},
		LimitReached: func(c fiber.Ctx) error {
			return utils.ErrorResponse(c, fiber.StatusTooManyRequests, "Rate limit exceeded. Please try again later.", fiber.Map{
				"retry_after": "60 seconds",
			})
		},
		SkipFailedRequests:     true, // Don't count failed requests
		SkipSuccessfulRequests: false,
		LimiterMiddleware:      limiter.SlidingWindow{},
	})
}
