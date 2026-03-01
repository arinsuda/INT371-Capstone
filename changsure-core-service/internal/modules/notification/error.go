package notification

import "errors"

var (
	ErrNotFound         = errors.New("notification not found")
	ErrInvalidRecipient = errors.New("invalid recipient role or id")
	ErrForbidden        = errors.New("access denied")
)
