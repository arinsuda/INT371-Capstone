package middleware

import (
	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/logger"
)

func Logger() fiber.Handler {
	return logger.New(logger.Config{
		Format:     "${time} | ${status} | ${latency} | ${ip} | ${method} | ${path} | ${error}\n",
		TimeFormat: "2006-01-02 15:04:05",
		TimeZone:   "Asia/Bangkok",
	})
}

func LoggerProduction() fiber.Handler {
	return logger.New(logger.Config{
		Format:     `{"time":"${time}","status":"${status}","latency":"${latency}","ip":"${ip}","method":"${method}","path":"${path}","user_agent":"${ua}","error":"${error}"}` + "\n",
		TimeFormat: "2006-01-02T15:04:05.999Z07:00",
		TimeZone:   "Asia/Bangkok",
	})
}
