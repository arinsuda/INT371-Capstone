package middleware

import (
	"strings"
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/limiter"
)

func RateLimit() fiber.Handler {
	return limiter.New(limiter.Config{
		Max:               1000,
		Expiration:        time.Minute,
		LimiterMiddleware: limiter.SlidingWindow{},
		KeyGenerator:      clientIP,
		LimitReached:      rateLimitExceeded("Rate limit exceeded. Please try again later.", ""),
	})
}

func StrictRateLimit() fiber.Handler {
	return limiter.New(limiter.Config{
		Max:                    30,
		Expiration:             time.Minute,
		LimiterMiddleware:      limiter.SlidingWindow{},
		KeyGenerator:           realClientIP,
		SkipFailedRequests:     true,
		SkipSuccessfulRequests: false,
		LimitReached:           rateLimitExceeded("Rate limit exceeded. Please try again later.", "60 seconds"),
	})
}

func clientIP(c fiber.Ctx) string {
	return c.Get("X-Forwarded-For", c.IP())
}

func realClientIP(c fiber.Ctx) string {
	fwd := c.Get("X-Forwarded-For")
	if fwd == "" {
		return c.IP()
	}

	return strings.TrimSpace(strings.SplitN(fwd, ",", 2)[0])
}

func rateLimitExceeded(message, retryAfter string) func(fiber.Ctx) error {
	return func(c fiber.Ctx) error {
		body := fiber.Map{
			"success": false,
			"message": message,
		}
		if retryAfter != "" {
			body["retry_after"] = retryAfter
		}
		return c.Status(fiber.StatusTooManyRequests).JSON(body)
	}
}
