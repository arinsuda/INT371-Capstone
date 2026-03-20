package auth

import "errors"

var (
	// Register
	ErrEmailAlreadyExists = errors.New("email already exists")
	ErrPhoneAlreadyExists = errors.New("phone number already exists")

	// Login
	ErrInvalidCredentials    = errors.New("invalid email or password")
	ErrTechnicianNotVerified = errors.New("account not verified — please upload your ID card")

	// Token
	ErrTokenInvalid         = errors.New("invalid token")
	ErrTokenExpired         = errors.New("token expired")
	ErrTokenRevoked         = errors.New("token has been revoked")
	ErrRefreshTokenNotFound = errors.New("refresh token not found or expired")

	// Role
	ErrInvalidRole = errors.New("invalid role")
)
