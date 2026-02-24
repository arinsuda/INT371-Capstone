package middleware

import (
	"fmt"
	"strings"
	"time"

	"changsure-core-service/internal/config"
	appErrors "changsure-core-service/internal/errors"

	"github.com/gofiber/fiber/v3"
	"github.com/golang-jwt/jwt/v5"
)

type contextKey string

const (
	LocalUserID   contextKey = "userID"
	LocalEmail    contextKey = "email"
	LocalRole     contextKey = "role"
	LocalUsername contextKey = "username"
)

const (
	RoleAdmin      = "admin"
	RoleCustomer   = "customer"
	RoleTechnician = "technician"
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

		claims, err := ParseToken(parts[1], secretKey)
		if err != nil {
			return jsonError(c, fiber.StatusUnauthorized, "Invalid or expired token", nil)
		}

		c.Locals(string(LocalUserID), claims.UserID)
		c.Locals(string(LocalEmail), claims.Email)
		c.Locals(string(LocalRole), claims.Role)
		c.Locals(string(LocalUsername), claims.Username)

		return c.Next()
	}
}

func AdminOnly() fiber.Handler {
	return RoleAuth(RoleAdmin)
}

func RoleAuth(allowedRoles ...string) fiber.Handler {
	allowed := make(map[string]struct{}, len(allowedRoles))
	for _, r := range allowedRoles {
		allowed[r] = struct{}{}
	}

	return func(c fiber.Ctx) error {
		role, ok := c.Locals(string(LocalRole)).(string)
		if !ok || role == "" {
			return jsonError(c, fiber.StatusForbidden, "Role information not found", nil)
		}

		if _, permitted := allowed[role]; !permitted {
			return jsonError(c, fiber.StatusForbidden, "Insufficient permissions", fiber.Map{
				"required_roles": allowedRoles,
				"user_role":      role,
			})
		}

		return c.Next()
	}
}

func GetUserID(c fiber.Ctx) (uint, bool) {
	id, ok := c.Locals(string(LocalUserID)).(uint)
	return id, ok && id != 0
}

func GetRole(c fiber.Ctx) (string, bool) {
	role, ok := c.Locals(string(LocalRole)).(string)
	return role, ok && role != ""
}

func GetEmail(c fiber.Ctx) (string, bool) {
	email, ok := c.Locals(string(LocalEmail)).(string)
	return email, ok && email != ""
}

func IsSelf(c fiber.Ctx, resourceOwnerID uint) bool {
	tokenUserID, ok := GetUserID(c)
	return ok && tokenUserID == resourceOwnerID
}

func IsAdmin(c fiber.Ctx) bool {
	role, ok := GetRole(c)
	return ok && role == RoleAdmin
}

func IsRole(c fiber.Ctx, roles ...string) bool {
	role, ok := GetRole(c)
	if !ok {
		return false
	}
	for _, r := range roles {
		if role == r {
			return true
		}
	}
	return false
}

func CanAccessResource(c fiber.Ctx, resourceOwnerID uint) bool {
	return IsSelf(c, resourceOwnerID) || IsAdmin(c)
}

func ParseToken(tokenStr, secret string) (*Claims, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return nil, fmt.Errorf("invalid token: %w", err)
	}
	return claims, nil
}

func GenerateAccessToken(userID uint, email, role, username, secret string, expireHours int) (string, error) {
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

func jsonError(c fiber.Ctx, code int, msg string, extra any) error {
	resp := fiber.Map{"success": false, "message": msg}
	if extra != nil {
		resp["data"] = extra
	}
	return c.Status(code).JSON(resp)
}

func CheckOwnerOrAdmin(c fiber.Ctx, resourceOwnerID uint) error {
	if CanAccessResource(c, resourceOwnerID) {
		return nil
	}
	return appErrors.NewForbidden(`You are not allowed to access this resource`)
}

func CheckAdmin(c fiber.Ctx) error {
	if IsAdmin(c) {
		return nil
	}
	return jsonError(c, fiber.StatusForbidden, "admin access required", nil)
}

func CheckRole(c fiber.Ctx, roles ...string) error {
	if IsRole(c, roles...) {
		return nil
	}
	return jsonError(c, fiber.StatusForbidden, "insufficient permissions", nil)
}
