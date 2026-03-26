package auth

import (
	customeraddress "changsure-core-service/internal/modules/customer_address"
	technicianaddress "changsure-core-service/internal/modules/technician_address"
	technicianservice "changsure-core-service/internal/modules/technician_service"
)

type RegisterCustomerRequest struct {
	Email           string `json:"email"            validate:"required,email"`
	Password        string `json:"password"         validate:"required,min=8"`
	ConfirmPassword string `json:"confirm_password" validate:"required,eqfield=Password"`
	FirstName       string `json:"firstname"        validate:"required,min=2,max=150"`
	LastName        string `json:"lastname"         validate:"required,min=2,max=150"`
	Phone           string `json:"phone"            validate:"required,len=10,numeric"`

	Address *customeraddress.CreateCustomerAddressRequest `json:"address,omitempty"`
}

type RegisterTechnicianRequest struct {
	Email           string                                            `json:"email"            validate:"required,email"`
	Password        string                                            `json:"password"         validate:"required,min=8"`
	ConfirmPassword string                                            `json:"confirm_password" validate:"required,eqfield=Password"`
	FirstName       string                                            `json:"firstname"        validate:"required,min=2,max=150"`
	LastName        string                                            `json:"lastname"         validate:"required,min=2,max=150"`
	Phone           string                                            `json:"phone"            validate:"required,len=10,numeric"`
	Address         *technicianaddress.CreateTechnicianAddressRequest `json:"address,omitempty"`
	Services        []technicianservice.ServicePatchItem              `json:"services,omitempty"`
	ProvinceIDs     []uint                                            `json:"province_ids,omitempty"`
	Consents        []string                                          `json:"consents" validate:"required,min=1"`
}

type RegisterCustomerResponse struct {
	CustomerID uint   `json:"customer_id"`
	Email      string `json:"email"`
	FirstName  string `json:"firstname"`
	LastName   string `json:"lastname"`
	Role       string `json:"role"`
	Message    string `json:"message"`
}

type RegisterTechnicianResponse struct {
	TechnicianID         uint         `json:"technician_id"`
	Email                string       `json:"email"`
	FirstName            string       `json:"firstname"`
	LastName             string       `json:"lastname"`
	Role                 string       `json:"role"`
	Message              string       `json:"message"`
	VerificationStatus   string       `json:"verification_status"`
	PreVerifiedToken     string       `json:"pre_verified_token"`
	PreVerifiedExpiresIn int64        `json:"pre_verified_expires_in"`
	NextStep             NextStepInfo `json:"next_step"`
}

type NextStepInfo struct {
	Action   string `json:"action"`
	Endpoint string `json:"endpoint"`
	Method   string `json:"method"`
}

type LoginRequest struct {
	Email    string `json:"email"    validate:"required,email"`
	Password string `json:"password" validate:"required,min=1"`
}

type LoginResponse struct {
	AccessToken  string   `json:"access_token"`
	RefreshToken string   `json:"refresh_token"`
	TokenType    string   `json:"token_type"`
	ExpiresIn    int64    `json:"expires_in"`
	User         UserInfo `json:"user"`
}

type UserInfo struct {
	ID                 uint   `json:"id"`
	Email              string `json:"email"`
	FirstName          string `json:"firstname"`
	LastName           string `json:"lastname"`
	Role               string `json:"role"`
	VerificationStatus string `json:"verification_status"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

type RefreshTokenResponse struct {
	AccessToken string `json:"access_token"`
	TokenType   string `json:"token_type"`
	ExpiresIn   int64  `json:"expires_in"`
}

type LogoutRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}
