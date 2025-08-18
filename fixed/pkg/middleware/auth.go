package middleware

import (
	"strings"
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/golang-jwt/jwt/v4"

	"fixed/configs"
	"fixed/utils"
)

type Claims struct {
	UserID uint   `json:"user_id"`
	Email  string `json:"email"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

func AuthMiddleware(config *configs.Config) fiber.Handler {
	return JWTAuth(config.JWT.Secret)
}

func JWTAuth(secretKey string) fiber.Handler {
	return func(c fiber.Ctx) error {
		// Get token from Authorization header
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return utils.ErrorResponse(c, fiber.StatusUnauthorized, "Authorization header required", nil)
		}

		// Check Bearer prefix
		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
			return utils.ErrorResponse(c, fiber.StatusUnauthorized, "Invalid authorization format", nil)
		}

		tokenString := tokenParts[1]

		// Parse and validate token
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			// Validate signing method
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, utils.NewError("Invalid signing method", fiber.StatusUnauthorized)
			}
			return []byte(secretKey), nil
		})

		if err != nil || !token.Valid {
			return utils.ErrorResponse(c, fiber.StatusUnauthorized, "Invalid or expired token", nil)
		}

		// Extract claims
		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			return utils.ErrorResponse(c, fiber.StatusUnauthorized, "Invalid token claims", nil)
		}

		// Set user info in context
		c.Locals("userID", claims["user_id"])
		c.Locals("email", claims["email"])
		c.Locals("role", claims["role"])
		c.Locals("username", claims["username"])

		return c.Next()
	}
}

// Role-based Authorization Middlewares
func AdminOnly() fiber.Handler {
	return RoleAuth("admin")
}

func ModeratorOnly() fiber.Handler {
	return RoleAuth("moderator")
}

func UserOrAdmin() fiber.Handler {
	return RoleAuth("user", "admin")
}

func ModeratorOrAdmin() fiber.Handler {
	return RoleAuth("moderator", "admin")
}

// RoleAuth middleware to check user roles
func RoleAuth(allowedRoles ...string) fiber.Handler {
	return func(c fiber.Ctx) error {
		// Get user role from context (set by AuthMiddleware)
		userRole, ok := c.Locals("role").(string)
		if !ok || userRole == "" {
			return utils.ErrorResponse(c, fiber.StatusForbidden, "Role information not found", nil)
		}

		// Check if user role is in allowed roles
		for _, role := range allowedRoles {
			if userRole == role {
				return c.Next()
			}
		}

		return utils.ErrorResponse(c, fiber.StatusForbidden, "Insufficient permissions", fiber.Map{
			"required_roles": allowedRoles,
			"user_role":      userRole,
		})
	}
}

// GenerateJWT generates a new JWT token
func GenerateJWT(userID uint, email, role, secret string, expireHours int) (string, error) {
	claims := &Claims{
		UserID: userID,
		Email:  email,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour * time.Duration(expireHours))),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}
