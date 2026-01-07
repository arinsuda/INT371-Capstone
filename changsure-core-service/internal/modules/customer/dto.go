package customers

import (
	customer_addresses "changsure-core-service/internal/modules/customer_address"
)

type CreateCustomerRequest struct {
	FirstName string  `json:"firstname"  validate:"required,min=2,max=150"`
	LastName  string  `json:"lastname"   validate:"required,min=2,max=150"`
	Email     *string `json:"email"      validate:"omitempty,email,max=100"`
	Phone     *string `json:"phone"      validate:"omitempty,len=10,numeric"`
	AvatarURL *string `json:"avatar_url" validate:"omitempty,max=255"`
}

type UpdateCustomerRequest struct {
	FirstName *string `json:"firstname"  validate:"omitempty,min=2,max=150"`
	LastName  *string `json:"lastname"   validate:"omitempty,min=2,max=150"`
	Email     *string `json:"email"      validate:"omitempty,email,max=100"`
	Phone     *string `json:"phone"      validate:"omitempty,len=10,numeric"`
	AvatarURL *string `json:"avatar_url" validate:"omitempty,max=255"`
}

type CustomerResponse struct {
	ID        uint    `json:"id"`
	FirstName string  `json:"firstname"`
	LastName  string  `json:"lastname"`
	Email     *string `json:"email,omitempty"`
	Phone     *string `json:"phone,omitempty"`
	AvatarURL *string `json:"avatar_url,omitempty"`
	CreatedAt string  `json:"created_at"`
	UpdatedAt string  `json:"updated_at"`

	Addresses []customer_addresses.CustomerAddressResponse `json:"addresses,omitempty"`
}
