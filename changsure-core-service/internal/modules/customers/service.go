package customers

import (
	"context"
	"errors"
	"fmt"

)

var (
	ErrCustomerNotFound    = errors.New("customer not found")
	ErrPhoneAlreadyExists  = errors.New("phone number already exists")
	ErrInvalidInput        = errors.New("invalid input")
)

// Service interface
type Service interface {
	CreateCustomer(ctx context.Context, req *CreateCustomerRequest) (*Customer, error)
	GetCustomer(ctx context.Context, id uint) (*Customer, error)
	UpdateCustomer(ctx context.Context, id uint, req *UpdateCustomerRequest) (*Customer, error)
	DeleteCustomer(ctx context.Context, id uint) error
	ListCustomers(ctx context.Context, page, pageSize int) ([]*Customer, error)
	FindNearbyCustomers(ctx context.Context, lat, lon, radiusKm float64) ([]*Customer, error)
}

// service struct
type service struct {
	repo Repository
}

// NewService creates a new customer service
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

// CreateCustomer creates a new customer
func (s *service) CreateCustomer(ctx context.Context, req *CreateCustomerRequest) (*Customer, error) {
	// Validate input
	if err := req.Validate(); err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalidInput, err)
	}

	// Check if phone already exists
	if req.Phone != nil {
		existing, err := s.repo.GetByPhone(ctx, *req.Phone)
		if err != nil {
			return nil, err
		}
		if existing != nil {
			return nil, ErrPhoneAlreadyExists
		}
	}

	// Create customer
	customer := &Customer{
		FullName:   req.FullName,
		Phone:      req.Phone,
		Address:    req.Address,
		Latitude:   req.Latitude,
		Longitude:  req.Longitude,
		ProvinceID: req.ProvinceID,
	}

	if err := s.repo.Create(ctx, customer); err != nil {
		return nil, fmt.Errorf("failed to create customer: %w", err)
	}

	// Reload with relations
	return s.repo.GetByID(ctx, customer.ID)
}

// GetCustomer retrieves a customer by ID
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

// UpdateCustomer updates an existing customer
func (s *service) UpdateCustomer(ctx context.Context, id uint, req *UpdateCustomerRequest) (*Customer, error) {
	// Check if customer exists
	customer, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if customer == nil {
		return nil, ErrCustomerNotFound
	}

	// Validate input
	if err := req.Validate(); err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalidInput, err)
	}

	// Check phone uniqueness if changed
	if req.Phone != nil && (customer.Phone == nil || *customer.Phone != *req.Phone) {
		existing, err := s.repo.GetByPhone(ctx, *req.Phone)
		if err != nil {
			return nil, err
		}
		if existing != nil && existing.ID != id {
			return nil, ErrPhoneAlreadyExists
		}
	}

	// Update fields
	if req.FullName != nil {
		customer.FullName = *req.FullName
	}
	if req.Phone != nil {
		customer.Phone = req.Phone
	}
	if req.Address != nil {
		customer.Address = req.Address
	}
	if req.Latitude != nil {
		customer.Latitude = req.Latitude
	}
	if req.Longitude != nil {
		customer.Longitude = req.Longitude
	}
	if req.ProvinceID != nil {
		customer.ProvinceID = req.ProvinceID
	}

	if err := s.repo.Update(ctx, customer); err != nil {
		return nil, fmt.Errorf("failed to update customer: %w", err)
	}

	return s.repo.GetByID(ctx, id)
}

// DeleteCustomer deletes a customer
func (s *service) DeleteCustomer(ctx context.Context, id uint) error {
	// Check if exists
	customer, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if customer == nil {
		return ErrCustomerNotFound
	}

	return s.repo.Delete(ctx, id)
}

// ListCustomers retrieves paginated customers
func (s *service) ListCustomers(ctx context.Context, page, pageSize int) ([]*Customer, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize
	return s.repo.List(ctx, pageSize, offset)
}

// FindNearbyCustomers finds customers within radius
func (s *service) FindNearbyCustomers(ctx context.Context, lat, lon, radiusKm float64) ([]*Customer, error) {
	if radiusKm <= 0 || radiusKm > 100 {
		return nil, fmt.Errorf("%w: radius must be between 0 and 100 km", ErrInvalidInput)
	}

	return s.repo.SearchNearby(ctx, lat, lon, radiusKm, 50)
}