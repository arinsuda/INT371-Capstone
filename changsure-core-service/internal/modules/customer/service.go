package customer

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	customer_addresses "changsure-core-service/internal/modules/customer_address"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"
)

var (
	ErrCustomerNotFound   = errors.New("customer not found")
	ErrPhoneAlreadyExists = errors.New("phone number already exists")
	ErrEmailAlreadyExists = errors.New("email already exists")
)

type Service interface {
	GetByID(ctx context.Context, id uint) (*CustomerResponse, error)
	List(ctx context.Context, page, pageSize int) ([]*CustomerResponse, error)
	Update(ctx context.Context, id uint, req *UpdateCustomerRequest) (*CustomerResponse, error)
	Delete(ctx context.Context, id uint) error
}

type service struct {
	repo    Repository
	storage storage.Storage
	logger  *slog.Logger
}

func NewService(repo Repository, s storage.Storage, logger *slog.Logger) Service {
	return &service{repo: repo, storage: s, logger: logger}
}

func (s *service) GetByID(ctx context.Context, id uint) (*CustomerResponse, error) {
	c, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("FindByID: %w", err)
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
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	customers, err := s.repo.GetAll(ctx, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("GetAll: %w", err)
	}

	out := make([]*CustomerResponse, len(customers))
	for i, c := range customers {
		out[i] = s.mapToResponse(ctx, c)
	}
	return out, nil
}

func (s *service) Update(ctx context.Context, id uint, req *UpdateCustomerRequest) (*CustomerResponse, error) {
	c, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("FindByID: %w", err)
	}
	if c == nil {
		return nil, ErrCustomerNotFound
	}

	if req.Phone != nil && (c.Phone == nil || *c.Phone != *req.Phone) {
		exist, err := s.repo.FindByPhone(ctx, *req.Phone)
		if err != nil {
			return nil, fmt.Errorf("FindByPhone: %w", err)
		}
		if exist != nil && exist.ID != id {
			return nil, ErrPhoneAlreadyExists
		}
		c.Phone = req.Phone
	}

	if req.Email != nil && (c.Email == nil || *c.Email != *req.Email) {
		exist, err := s.repo.FindByEmail(ctx, *req.Email)
		if err != nil {
			return nil, fmt.Errorf("FindByEmail: %w", err)
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
		return nil, fmt.Errorf("Update: %w", err)
	}

	callerID := utils.GetUserIDFromContext(ctx)
	s.logger.Info("customer updated", "customer_id", id, "updated_by", callerID)

	return s.mapToResponse(ctx, c), nil
}

func (s *service) Delete(ctx context.Context, id uint) error {
	exists, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return fmt.Errorf("FindByID: %w", err)
	}
	if exists == nil {
		return ErrCustomerNotFound
	}
	return s.repo.Delete(ctx, id)
}

func (s *service) mapToResponse(ctx context.Context, c *Customer) *CustomerResponse {
	resp := &CustomerResponse{
		ID:        c.ID,
		FirstName: c.FirstName,
		LastName:  c.LastName,
		Email:     c.Email,
		Phone:     c.Phone,
		CreatedAt: c.CreatedAt.Format(time.RFC3339),
		UpdatedAt: c.UpdatedAt.Format(time.RFC3339),
	}

	if c.AvatarURL != nil && *c.AvatarURL != "" && s.storage != nil {
		url, err := s.storage.PresignGet(ctx, *c.AvatarURL, time.Hour, false)
		if err != nil {
			s.logger.Warn("failed to presign avatar url", "customer_id", c.ID, "error", err)
			resp.AvatarURL = c.AvatarURL
		} else {
			resp.AvatarURL = &url
		}
	}

	if len(c.Addresses) > 0 {
		resp.Addresses = make([]customer_addresses.CustomerAddressResponse, 0, len(c.Addresses))
		for _, a := range c.Addresses {
			resp.Addresses = append(resp.Addresses, customer_addresses.ToResponse(&a, c.Phone))
		}
	}

	return resp
}
