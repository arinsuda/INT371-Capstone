package emailverification

import "errors"

var (
	ErrOTPNotFound    = errors.New("OTP not found or already verified")
	ErrOTPExpired     = errors.New("OTP has expired — please request a new one")
	ErrOTPInvalid     = errors.New("invalid OTP")
	ErrOTPMaxAttempts = errors.New("too many failed attempts — please request a new OTP")
	ErrResendTooSoon  = errors.New("please wait before requesting a new OTP")
)