package middleware

import (
	"fmt"
	"strings"
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/golang-jwt/jwt/v4"

	"changsure-core-service/internal/config"
)

type Claims struct {
	UserID   uint   `json:"user_id"`
	Email    string `json:"email"`
	Role     string `json:"role"`
	Username string `json:"username,omitempty"`
	jwt.RegisteredClaims
}

func AuthMiddleware(cfg *config.Config) fiber.Handler {
	return JWTAuth(cfg.JWT.Secret)
}

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

		auth := c.Get("Authorization")
		if auth == "" {
			return jsonError(c, fiber.StatusUnauthorized, "Authorization header required", nil)
		}

		parts := strings.SplitN(auth, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" {
			return jsonError(c, fiber.StatusUnauthorized, "Invalid authorization format", nil)
		}
		tokenStr := parts[1]

		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (interface{}, error) {

			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fiber.ErrUnauthorized
			}
			return []byte(secretKey), nil
		})
		if err != nil || !token.Valid {
			return jsonError(c, fiber.StatusUnauthorized, "Invalid or expired token", nil)
		}

		c.Locals("userID", claims.UserID)
		c.Locals("email", claims.Email)
		c.Locals("role", claims.Role)
		c.Locals("username", claims.Username)

		return c.Next()
	}
}

func AdminOnly() fiber.Handler { return RoleAuth("admin") }

func CustomerOnly() fiber.Handler {
	return RoleAuth("customer")
}

func TechnicianOnly() fiber.Handler {
	return RoleAuth("technician")
}

func CustomerOrTechnician() fiber.Handler {
	return RoleAuth("customer", "technician")
}

func RoleAuth(allowedRoles ...string) fiber.Handler {
	return func(c fiber.Ctx) error {
		role, ok := c.Locals("role").(string)
		if !ok || role == "" {
			return jsonError(c, fiber.StatusForbidden, "Role information not found", nil)
		}

		// เพิ่ม log เพื่อ debug
		fmt.Printf("User role from token: '%s', Required roles: %v\n", role, allowedRoles)

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

func ParseToken(tokenStr, secret string) (*Claims, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fiber.ErrUnauthorized
		}
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return nil, fiber.ErrUnauthorized
	}
	return claims, nil
}

func generateToken(
	userID uint,
	email, role, username, secret string,
	expireHours int,
) (string, error) {
	now := time.Now()
	claims := &Claims{
		UserID:   userID,
		Email:    email,
		Role:     role,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(time.Duration(expireHours) * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
		},
	}

	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return tok.SignedString([]byte(secret))
}

func GenerateAccessToken(
	userID uint,
	email, role, username, secret string,
	expireHours int,
) (string, error) {
	return generateToken(userID, email, role, username, secret, expireHours)
}
