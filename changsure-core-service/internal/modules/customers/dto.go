package customers

import (
	"errors"
	"regexp"
	"strings"
	"time"

	customer_addresses "changsure-core-service/internal/modules/customer_addresses"

	"changsure-core-service/pkg/storage"
)

type CreateCustomerRequest struct {
	FirstName string  `json:"firstname"   validate:"required,min=2,max=150"`
	LastName  string  `json:"lastname"    validate:"required,min=2,max=150"`
	Email     *string `json:"email"       validate:"omitempty,max=100"`
	Phone     *string `json:"phone"       validate:"omitempty,max=10"`
	AvatarURL *string `json:"avatar_url"  validate:"omitempty,max=255"`
}

func (r *CreateCustomerRequest) Validate() error {
	if s := strings.TrimSpace(r.FirstName); len(s) < 2 || len(s) > 150 {
		return errors.New("firstname must be between 2 and 150 characters")
	}
	if s := strings.TrimSpace(r.LastName); len(s) < 2 || len(s) > 150 {
		return errors.New("lastname must be between 2 and 150 characters")
	}
	if r.Email != nil {
		if len(*r.Email) > 100 || !isBasicEmail(*r.Email) {
			return errors.New("invalid email format or length > 100")
		}
	}
	if r.Phone != nil {
		if len(*r.Phone) > 10 || !isDigits(*r.Phone) {
			return errors.New("phone must be digits and at most 10 characters")
		}
	}
	if r.AvatarURL != nil && len(*r.AvatarURL) > 255 {
		return errors.New("avatar_url length must be <= 255")
	}
	return nil
}

type UpdateCustomerRequest struct {
	FirstName *string `json:"firstname"   validate:"omitempty,min=2,max=150"`
	LastName  *string `json:"lastname"    validate:"omitempty,min=2,max=150"`
	Email     *string `json:"email"       validate:"omitempty,max=100"`
	Phone     *string `json:"phone"       validate:"omitempty,max=10"`
	AvatarURL *string `json:"avatar_url"  validate:"omitempty,max=255"`
}

func (r *UpdateCustomerRequest) Validate() error {
	if r.FirstName != nil {
		s := strings.TrimSpace(*r.FirstName)
		if len(s) < 2 || len(s) > 150 {
			return errors.New("firstname must be between 2 and 150 characters")
		}
	}
	if r.LastName != nil {
		s := strings.TrimSpace(*r.LastName)
		if len(s) < 2 || len(s) > 150 {
			return errors.New("lastname must be between 2 and 150 characters")
		}
	}
	if r.Email != nil {
		if len(*r.Email) > 100 || !isBasicEmail(*r.Email) {
			return errors.New("invalid email format or length > 100")
		}
	}
	if r.Phone != nil {
		if len(*r.Phone) > 10 || !isDigits(*r.Phone) {
			return errors.New("phone must be digits and at most 10 characters")
		}
	}
	if r.AvatarURL != nil && len(*r.AvatarURL) > 255 {
		return errors.New("avatar_url length must be <= 255")
	}
	return nil
}

type CustomerResponse struct {
	ID        uint                                         `json:"id"`
	FirstName string                                       `json:"firstname"`
	LastName  string                                       `json:"lastname"`
	Email     *string                                      `json:"email,omitempty"`
	Phone     *string                                      `json:"phone,omitempty"`
	AvatarURL *string                                      `json:"avatar_url,omitempty"`
	CreatedAt string                                       `json:"created_at"`
	UpdatedAt string                                       `json:"updated_at"`
	Addresses []customer_addresses.CustomerAddressResponse `json:"addresses,omitempty"`
}

type ProvinceResponse struct {
	ID     uint   `json:"id"`
	NameTH string `json:"name_th"`
}

func ToCustomerResponse(c *Customer) *CustomerResponse {
	var avatar string

	if c.AvatarURL != nil && *c.AvatarURL != "" && storage.GlobalMinio != nil {
		avatar = storage.GlobalMinio.PublicURL(*c.AvatarURL)
	}

	resp := &CustomerResponse{
		ID:        c.ID,
		FirstName: c.FirstName,
		LastName:  c.LastName,
		Email:     c.Email,
		Phone:     c.Phone,
		AvatarURL: &avatar,
		CreatedAt: c.CreatedAt.Format(time.RFC3339),
		UpdatedAt: c.UpdatedAt.Format(time.RFC3339),
	}

	// ----- Address -----
	// ----- Address -----
	if len(c.Addresses) > 0 {
		resp.Addresses = make([]customer_addresses.CustomerAddressResponse, 0, len(c.Addresses))
		for _, a := range c.Addresses {

			item := customer_addresses.CustomerAddressResponse{
				ID:          a.ID,
				HouseNumber: a.HouseNumber,
				Village:     a.Village,
				Moo:         a.Moo,
				Soi:         a.Soi,
				Road:        a.Road,
				SubDistrict: a.SubDistrict,
				District:    a.District,
				Province:    a.Province,   
				ProvinceID:  a.ProvinceID,
				PostalCode:  a.PostalCode,
				Country:     a.Country,
				Latitude:    a.Latitude,
				Longitude:   a.Longitude,
				IsPrimary:   a.IsPrimary,
				CreatedAt:   a.CreatedAt.Format(time.RFC3339),
				UpdatedAt:   a.UpdatedAt.Format(time.RFC3339),
			}

			resp.Addresses = append(resp.Addresses, item)
		}
	}

	return resp
}

func ToCustomerResponseList(list []*Customer) []*CustomerResponse {
	out := make([]*CustomerResponse, len(list))
	for i, c := range list {
		out[i] = ToCustomerResponse(c)
	}
	return out
}

func isDigits(s string) bool {
	if s == "" {
		return false
	}
	for _, r := range s {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}

func isBasicEmail(s string) bool {
	re := regexp.MustCompile(`^[^@\s]+@[^@\s]+\.[^@\s]+$`)
	return re.MatchString(s)
}
