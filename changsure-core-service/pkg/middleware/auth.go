package middleware

import (
	"strings"
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/golang-jwt/jwt/v4"

	"changsure-core-service/configs"
)

type Claims struct {
	UserID   uint   `json:"user_id"`
	Email    string `json:"email"`
	Role     string `json:"role"`
	Username string `json:"username,omitempty"`
	jwt.RegisteredClaims
}

// ใช้ใน main/setup เพื่อผูก middleware (ดึง secret จาก config)
func AuthMiddleware(cfg *configs.Config) fiber.Handler {
	return JWTAuth(cfg.JWT.Secret)
}

// ตัวช่วยตอบ error แบบมาตรฐาน (เลี่ยงการพึ่งพา utils)
func jsonError(c fiber.Ctx, code int, msg string, extra any) error {
	resp := fiber.Map{
		"success": false,
		"message": msg,
	}
	if extra != nil {
		resp["data"] = extra
	}
	return c.Status(code).JSON(resp)
}

func JWTAuth(secretKey string) fiber.Handler {
	return func(c fiber.Ctx) error {
		// Authorization: Bearer <token>
		auth := c.Get("Authorization")
		if auth == "" {
			return jsonError(c, fiber.StatusUnauthorized, "Authorization header required", nil)
		}

		parts := strings.SplitN(auth, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" {
			return jsonError(c, fiber.StatusUnauthorized, "Invalid authorization format", nil)
		}
		tokenStr := parts[1]

		// พาร์สเป็น struct Claims เพื่อความปลอดภัยของชนิดข้อมูล
		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (interface{}, error) {
			// ตรวจวิธีลงนามเป็น HMAC เท่านั้น
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fiber.ErrUnauthorized
			}
			return []byte(secretKey), nil
		})
		if err != nil || !token.Valid {
			return jsonError(c, fiber.StatusUnauthorized, "Invalid or expired token", nil)
		}

		// ตั้งค่า context ให้ handler ถัดไปใช้งาน
		c.Locals("userID", claims.UserID)
		c.Locals("email", claims.Email)
		c.Locals("role", claims.Role)
		c.Locals("username", claims.Username)

		return c.Next()
	}
}

// ------- Role-based Authorization -------

func AdminOnly() fiber.Handler        { return RoleAuth("admin") }
func ModeratorOnly() fiber.Handler    { return RoleAuth("moderator") }
func UserOrAdmin() fiber.Handler      { return RoleAuth("user", "admin") }
func ModeratorOrAdmin() fiber.Handler { return RoleAuth("moderator", "admin") }

func RoleAuth(allowedRoles ...string) fiber.Handler {
	return func(c fiber.Ctx) error {
		role, ok := c.Locals("role").(string)
		if !ok || role == "" {
			return jsonError(c, fiber.StatusForbidden, "Role information not found", nil)
		}
		for _, r := range allowedRoles {
			if role == r {
				return c.Next()
			}
		}
		return jsonError(c, fiber.StatusForbidden, "Insufficient permissions", fiber.Map{
			"required_roles": allowedRoles,
			"user_role":      role,
		})
	}
}

// ------- Helpers to issue tokens -------

func GenerateJWT(userID uint, email, role, username, secret string, expireHours int) (string, error) {
	now := time.Now()
	claims := &Claims{
		UserID:   userID,
		Email:    email,
		Role:     role,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			// ตั้งหมดอายุ
			ExpiresAt: jwt.NewNumericDate(now.Add(time.Duration(expireHours) * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
		},
	}
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return tok.SignedString([]byte(secret))
}
