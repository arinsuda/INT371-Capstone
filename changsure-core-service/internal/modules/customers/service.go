package customers

import (
	"context"
	"errors"
	"fmt"
)

var (
	ErrCustomerNotFound   = errors.New("customer not found")
	ErrPhoneAlreadyExists = errors.New("phone number already exists")
	ErrEmailAlreadyExists = errors.New("email already exists")
	ErrInvalidInput       = errors.New("invalid input")
)

type Service interface {
	CreateCustomer(ctx context.Context, req *CreateCustomerRequest) (*Customer, error)
	GetCustomer(ctx context.Context, id uint) (*Customer, error)
	UpdateCustomer(ctx context.Context, id uint, req *UpdateCustomerRequest) (*Customer, error)
	DeleteCustomer(ctx context.Context, id uint) error
	ListCustomers(ctx context.Context, page, pageSize int) ([]*Customer, error)

	FindNearbyAddresses(ctx context.Context, lat, lon, radiusKm float64) ([]*Customer, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) CreateCustomer(ctx context.Context, req *CreateCustomerRequest) (*Customer, error) {
	if err := req.Validate(); err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalidInput, err)
	}

	if req.Phone != nil {
		existing, err := s.repo.GetByPhone(ctx, *req.Phone)
		if err != nil {
			return nil, err
		}
		if existing != nil {
			return nil, ErrPhoneAlreadyExists
		}
	}

	if req.Email != nil {
		existing, err := s.repo.GetByEmail(ctx, *req.Email)
		if err != nil {
			return nil, err
		}
		if existing != nil {
			return nil, ErrEmailAlreadyExists
		}
	}

	customer := &Customer{
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     req.Email,
		Phone:     req.Phone,
		AvatarURL: req.AvatarURL,
	}

	if err := s.repo.Create(ctx, customer); err != nil {
		return nil, fmt.Errorf("failed to create customer: %w", err)
	}

	return s.repo.GetByID(ctx, customer.ID)
}

func (s *service) GetCustomer(ctx context.Context, id uint) (*Customer, error) {
	customer, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if customer == nil {
		return nil, ErrCustomerNotFound
	}
	return customer, nil
}

func (s *service) UpdateCustomer(ctx context.Context, id uint, req *UpdateCustomerRequest) (*Customer, error) {
	customer, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if customer == nil {
		return nil, ErrCustomerNotFound
	}

	if err := req.Validate(); err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalidInput, err)
	}

	if req.Phone != nil && (customer.Phone == nil || *customer.Phone != *req.Phone) {
		existing, err := s.repo.GetByPhone(ctx, *req.Phone)
		if err != nil {
			return nil, err
		}
		if existing != nil && existing.ID != id {
			return nil, ErrPhoneAlreadyExists
		}
	}

	if req.Email != nil && (customer.Email == nil || *customer.Email != *req.Email) {
		existing, err := s.repo.GetByEmail(ctx, *req.Email)
		if err != nil {
			return nil, err
		}
		if existing != nil && existing.ID != id {
			return nil, ErrEmailAlreadyExists
		}
	}

	if req.FirstName != nil {
		customer.FirstName = *req.FirstName
	}
	if req.LastName != nil {
		customer.LastName = *req.LastName
	}
	if req.Email != nil {
		customer.Email = req.Email
	}
	if req.Phone != nil {
		customer.Phone = req.Phone
	}
	if req.AvatarURL != nil {
		customer.AvatarURL = req.AvatarURL
	}

	if err := s.repo.Update(ctx, customer); err != nil {
		return nil, fmt.Errorf("failed to update customer: %w", err)
	}

	return s.repo.GetByID(ctx, id)
}

func (s *service) DeleteCustomer(ctx context.Context, id uint) error {
	exists, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if exists == nil {
		return ErrCustomerNotFound
	}
	return s.repo.Delete(ctx, id)
}

func (s *service) ListCustomers(ctx context.Context, page, pageSize int) ([]*Customer, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize
	return s.repo.GetAll(ctx, pageSize, offset)
}

func (s *service) FindNearbyAddresses(ctx context.Context, lat, lon, radiusKm float64) ([]*Customer, error) {
	if radiusKm <= 0 || radiusKm > 100 {
		return nil, fmt.Errorf("%w: radius must be between 0 and 100 km", ErrInvalidInput)
	}
	return s.repo.SearchNearbyAddresses(ctx, lat, lon, radiusKm, 50)
}
