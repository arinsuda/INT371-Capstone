package addressshared

import "errors"

var (
	ErrAddressNotFound = errors.New("address not found")
	ErrUnauthorized    = errors.New("you do not own this address")
	ErrInvalidLocation = errors.New("invalid location hierarchy")
)
