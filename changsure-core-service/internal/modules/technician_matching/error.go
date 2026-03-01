package technicianmatching

import "errors"

var (
	ErrUnauthorized       = errors.New("unauthorized")
	ErrInvalidInput       = errors.New("invalid input")
	ErrTechnicianNotFound = errors.New("technician not found")
	ErrNoCustomerAddress  = errors.New("customer has no primary address")
	ErrNoTechnicianFound  = errors.New("no technician matches the criteria")
)
