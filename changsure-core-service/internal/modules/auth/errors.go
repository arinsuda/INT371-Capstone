package auth

import "errors"

var (
	// Register
	ErrEmailAlreadyExists = errors.New("email already exists")
	ErrPhoneAlreadyExists = errors.New("phone number already exists")

	// Login
	ErrInvalidCredentials      = errors.New("invalid email or password")
	ErrTechnicianNotVerified   = errors.New("account not verified — please upload your ID card")
	ErrTechnicianVerifyFailed  = errors.New("identity verification failed — criminal record found")
	ErrTechnicianVerifyPending = errors.New("identity verification is pending admin review")
	ErrTechnicianBanned        = errors.New("account has been suspended — please contact support")

	// Token
	ErrTokenInvalid         = errors.New("invalid token")
	ErrTokenExpired         = errors.New("token expired")
	ErrTokenRevoked         = errors.New("token has been revoked")
	ErrRefreshTokenNotFound = errors.New("refresh token not found or expired")

	// Role
	ErrInvalidRole = errors.New("invalid role")
)
