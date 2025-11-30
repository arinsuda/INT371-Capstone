package address_shared

import "errors"

var (
	ErrAddressNotFound = errors.New("address not found")
	ErrUnauthorized    = errors.New("you do not own this address")
)
