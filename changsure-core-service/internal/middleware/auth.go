package middleware

import (
	"strings"

	"changsure-core-service/internal/config"
	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/jwtutil"

	"github.com/gofiber/fiber/v3"
)

const (
	LocalUserID             = "userID"
	LocalEmail              = "email"
	LocalRole               = "role"
	LocalVerificationStatus = "verificationStatus"
	LocalScope              = "scope"
)

func AuthMiddleware(cfg *config.Config) fiber.Handler {
	return JWTAuth(cfg.JWT.Secret)
}

func JWTAuth(secretKey string) fiber.Handler {
	return func(c fiber.Ctx) error {
		raw, err := extractBearerToken(c)
		if err != nil {
			return jsonError(c, fiber.StatusUnauthorized, err.Error(), nil)
		}

		claims, err := jwtutil.ParseString(secretKey, raw)
		if err != nil {
			return jsonError(c, fiber.StatusUnauthorized, "invalid or expired token", nil)
		}

		if claims.TokenType != jwtutil.TokenTypeAccess {
			return jsonError(c, fiber.StatusUnauthorized, "invalid token type", nil)
		}

		c.Locals(LocalUserID, claims.UserID)
		c.Locals(LocalEmail, claims.Email)
		c.Locals(LocalRole, claims.Role)
		c.Locals(LocalVerificationStatus, claims.VerificationStatus)
		c.Locals(LocalScope, claims.Scope)

		return c.Next()
	}
}

func extractBearerToken(c fiber.Ctx) (string, error) {
	authHeader := c.Get("Authorization")
	if authHeader == "" {
		return "", &authError{"authorization header required"}
	}
	parts := strings.SplitN(authHeader, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" {
		return "", &authError{"invalid authorization format, expected: Bearer <token>"}
	}
	return parts[1], nil
}

type authError struct{ msg string }

func (e *authError) Error() string { return e.msg }

func AdminOnly() fiber.Handler {
	return RoleAuth(jwtutil.RoleAdmin)
}

func RoleAuth(allowedRoles ...string) fiber.Handler {
	allowed := make(map[string]struct{}, len(allowedRoles))
	for _, r := range allowedRoles {
		allowed[r] = struct{}{}
	}
	return func(c fiber.Ctx) error {
		role, ok := c.Locals(LocalRole).(string)
		if !ok || role == "" {
			return jsonError(c, fiber.StatusForbidden, "role information not found", nil)
		}
		if _, permitted := allowed[role]; !permitted {
			return jsonError(c, fiber.StatusForbidden, "insufficient permissions", fiber.Map{
				"required_roles": allowedRoles,
				"user_role":      role,
			})
		}
		return c.Next()
	}
}

func TechnicianVerifiedOnly() fiber.Handler {
	return func(c fiber.Ctx) error {
		role, _ := c.Locals(LocalRole).(string)
		if role != jwtutil.RoleTechnician {
			return c.Next()
		}

		status, _ := c.Locals(LocalVerificationStatus).(string)

		if status != "PASSED" {
			return jsonError(c, fiber.StatusForbidden,
				"account not verified — please upload your ID card", nil)
		}

		return c.Next()
	}
}

func PreVerifiedAuth(secretKey string) fiber.Handler {
	return func(c fiber.Ctx) error {
		raw, err := extractBearerToken(c)
		if err != nil {
			return jsonError(c, fiber.StatusUnauthorized, err.Error(), nil)
		}

		claims, err := jwtutil.ParseString(secretKey, raw)
		if err != nil {
			return jsonError(c, fiber.StatusUnauthorized, "invalid or expired token", nil)
		}

		if claims.TokenType != jwtutil.TokenTypeAccess {
			return jsonError(c, fiber.StatusUnauthorized, "invalid token type", nil)
		}

		if claims.Scope != jwtutil.ScopePreVerified {
			return jsonError(c, fiber.StatusForbidden, "token scope not permitted for this endpoint", nil)
		}

		c.Locals(LocalUserID, claims.UserID)
		c.Locals(LocalEmail, claims.Email)
		c.Locals(LocalRole, claims.Role)
		c.Locals(LocalScope, claims.Scope)
		return c.Next()
	}
}

func GetUserID(c fiber.Ctx) (uint, bool) {
	id, ok := c.Locals(LocalUserID).(uint)
	return id, ok && id != 0
}

func GetRole(c fiber.Ctx) (string, bool) {
	role, ok := c.Locals(LocalRole).(string)
	return role, ok && role != ""
}

func GetEmail(c fiber.Ctx) (string, bool) {
	email, ok := c.Locals(LocalEmail).(string)
	return email, ok && email != ""
}

func GetVerificationStatus(c fiber.Ctx) string {
	s, _ := c.Locals(LocalVerificationStatus).(string)
	return s
}

func GetScope(c fiber.Ctx) string {
	s, _ := c.Locals(LocalScope).(string)
	return s
}

func IsAdmin(c fiber.Ctx) bool {
	role, ok := GetRole(c)
	return ok && role == jwtutil.RoleAdmin
}

func IsSelf(c fiber.Ctx, resourceOwnerID uint) bool {
	tokenUserID, ok := GetUserID(c)
	return ok && tokenUserID == resourceOwnerID
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

func CheckOwnerOrAdmin(c fiber.Ctx, resourceOwnerID uint) error {
	if CanAccessResource(c, resourceOwnerID) {
		return nil
	}
	return appErrors.NewForbidden("you are not allowed to access this resource")
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

func jsonError(c fiber.Ctx, code int, msg string, extra any) error {
	resp := fiber.Map{"success": false, "message": msg}
	if extra != nil {
		resp["data"] = extra
	}
	return c.Status(code).JSON(resp)
}
