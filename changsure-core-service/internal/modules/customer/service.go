package customers

import (
	"context"
	"errors"
	"time"

	customer_addresses "changsure-core-service/internal/modules/customer_address"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"
)

var (
	ErrCustomerNotFound   = errors.New("customer not found")
	ErrPhoneAlreadyExists = errors.New("phone number already exists")
	ErrEmailAlreadyExists = errors.New("email already exists")
	ErrUnauthorized       = errors.New("unauthorized action")
)

type Service interface {
	GetProfile(ctx context.Context, id uint) (*CustomerResponse, error)
	UpdateProfile(ctx context.Context, id uint, req *UpdateCustomerRequest) (*CustomerResponse, error)

	GetByID(ctx context.Context, id uint) (*CustomerResponse, error)
	List(ctx context.Context, page, pageSize int) ([]*CustomerResponse, error)
	Delete(ctx context.Context, id uint) error

	Update(ctx context.Context, id uint, req *UpdateCustomerRequest) (*CustomerResponse, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) checkOwner(ctx context.Context, resourceID uint) error {
	userID := utils.GetUserIDFromContext(ctx)
	if userID == 0 || userID != resourceID {
		return ErrUnauthorized
	}
	return nil
}

func (s *service) GetProfile(ctx context.Context, id uint) (*CustomerResponse, error) {
	if err := s.checkOwner(ctx, id); err != nil {
		return nil, err
	}
	return s.GetByID(ctx, id)
}

func (s *service) UpdateProfile(ctx context.Context, id uint, req *UpdateCustomerRequest) (*CustomerResponse, error) {
	if err := s.checkOwner(ctx, id); err != nil {
		return nil, err
	}
	return s.Update(ctx, id, req)
}

func (s *service) GetByID(ctx context.Context, id uint) (*CustomerResponse, error) {
	c, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if c == nil {
		return nil, ErrCustomerNotFound
	}
	return s.mapToResponse(ctx, c), nil
}

func (s *service) List(ctx context.Context, page, pageSize int) ([]*CustomerResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	customers, err := s.repo.GetAll(ctx, pageSize, offset)
	if err != nil {
		return nil, err
	}

	out := make([]*CustomerResponse, len(customers))
	for i, c := range customers {
		out[i] = s.mapToResponse(ctx, c)
	}
	return out, nil
}

func (s *service) Delete(ctx context.Context, id uint) error {

	exists, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return err
	}
	if exists == nil {
		return ErrCustomerNotFound
	}

	return s.repo.Delete(ctx, id)
}

func (s *service) Update(ctx context.Context, id uint, req *UpdateCustomerRequest) (*CustomerResponse, error) {
	c, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if c == nil {
		return nil, ErrCustomerNotFound
	}

	if req.Phone != nil && (c.Phone == nil || *c.Phone != *req.Phone) {
		exist, err := s.repo.FindByPhone(ctx, *req.Phone)
		if err != nil {
			return nil, err
		}
		if exist != nil && exist.ID != id {
			return nil, ErrPhoneAlreadyExists
		}
		c.Phone = req.Phone
	}

	if req.Email != nil && (c.Email == nil || *c.Email != *req.Email) {
		exist, err := s.repo.FindByEmail(ctx, *req.Email)
		if err != nil {
			return nil, err
		}
		if exist != nil && exist.ID != id {
			return nil, ErrEmailAlreadyExists
		}
		c.Email = req.Email
	}

	if req.FirstName != nil {
		c.FirstName = *req.FirstName
	}
	if req.LastName != nil {
		c.LastName = *req.LastName
	}
	if req.AvatarURL != nil {
		c.AvatarURL = req.AvatarURL
	}

	if err := s.repo.Update(ctx, c); err != nil {
		return nil, err
	}

	return s.mapToResponse(ctx, c), nil
}

func (s *service) mapToResponse(ctx context.Context, c *Customer) *CustomerResponse {
	var signedAvatar *string

	if c.AvatarURL != nil && *c.AvatarURL != "" && storage.GlobalMinio != nil {
		url, err := storage.GlobalMinio.PresignGet(ctx, *c.AvatarURL, time.Hour, false)
		if err == nil {
			signedAvatar = &url
		} else {
			signedAvatar = c.AvatarURL
		}
	}

	resp := &CustomerResponse{
		ID:        c.ID,
		FirstName: c.FirstName,
		LastName:  c.LastName,
		Email:     c.Email,
		Phone:     c.Phone,
		AvatarURL: signedAvatar,
		CreatedAt: c.CreatedAt.Format(time.RFC3339),
		UpdatedAt: c.UpdatedAt.Format(time.RFC3339),
	}

	if len(c.Addresses) > 0 {
		resp.Addresses = make([]customer_addresses.CustomerAddressResponse, 0, len(c.Addresses))
		for _, a := range c.Addresses {
			resp.Addresses = append(resp.Addresses, customer_addresses.ToResponse(&a, c.Phone))
		}
	}

	return resp
}
