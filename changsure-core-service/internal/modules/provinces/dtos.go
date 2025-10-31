package provinces

import (
	"errors"
	"strings"
	"time"
)

type CreateProvinceRequest struct {
	NameTH string  `json:"name_th" validate:"required,min=2,max=100"`
}

func (r *CreateProvinceRequest) Validate() error {
	if strings.TrimSpace(r.NameTH) == "" {
		return errors.New("name_th is required")
	}
	if len(r.NameTH) < 2 || len(r.NameTH) > 100 {
		return errors.New("name_th must be between 2 and 100 characters")
	}
	return nil
}

type UpdateProvinceRequest struct {
	NameTH *string `json:"name_th" validate:"omitempty,min=2,max=100"`
}

func (r *UpdateProvinceRequest) Validate() error {
	if r.NameTH != nil {
		s := strings.TrimSpace(*r.NameTH)
		if len(s) < 2 || len(s) > 100 {
			return errors.New("name_th must be between 2 and 100 characters")
		}
	}

	return nil
}

type ProvinceResponse struct {
	ID        uint    `json:"id"`
	NameTH    string  `json:"name_th"`
	CreatedAt string  `json:"created_at"`
	UpdatedAt string  `json:"updated_at"`
}

func ToResponse(p *Province) *ProvinceResponse {
	return &ProvinceResponse{
		ID:        p.ID,
		NameTH:    p.NameTH,
		CreatedAt: p.CreatedAt.Format(time.RFC3339),
		UpdatedAt: p.UpdatedAt.Format(time.RFC3339),
	}
}

func ToResponseList(list []*Province) []*ProvinceResponse {
	out := make([]*ProvinceResponse, len(list))
	for i, p := range list {
		out[i] = ToResponse(p)
	}
	return out
}