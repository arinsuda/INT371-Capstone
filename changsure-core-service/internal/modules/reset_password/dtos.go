package resetpassword

type ForgotPasswordRequest struct {
	Email string `json:"email" validate:"required,email"`
}

type VerifyOTPRequest struct {
	Email string `json:"email" validate:"required,email"`
	OTP   string `json:"otp"   validate:"required,len=6,numeric"`
}

type ResetPasswordRequest struct {
	ResetToken      string `json:"reset_token"       validate:"required"`
	NewPassword     string `json:"new_password"      validate:"required,min=8,max=72"`
	ConfirmPassword string `json:"confirm_password"  validate:"required,eqfield=NewPassword"`
}

type ForgotPasswordResponse struct {
	Message   string  `json:"message"`
	ExpiresIn int     `json:"expires_in"`
	OTP       *string `json:"otp,omitempty"`
}

type VerifyOTPResponse struct {
	Message    string `json:"message"`
	ResetToken string `json:"reset_token"`
}

type ResetPasswordResponse struct {
	Message string `json:"message"`
}