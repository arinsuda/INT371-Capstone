package payment

import (
	"errors"
	"fmt"
)

var (
	ErrInvalidPaymentID = errors.New("invalid payment ID")

	ErrInvalidAmount = errors.New("invalid amount: must be greater than 0")

	ErrPaymentProviderUnavailable = errors.New("payment provider is currently unavailable")

	ErrSourceCreationFailed = errors.New("failed to create payment source")

	ErrInvalidCurrency = errors.New("invalid or unsupported currency")

	ErrAmountNotMatchFixedPrice = errors.New(
		"amount must equal quoted fixed price",
	)

	ErrAmountOutOfRange = errors.New(
		"amount must be within quoted price range",
	)

	ErrFixedPriceNotSet = errors.New(
		"quoted fixed price is not set",
	)

	ErrRangePriceNotSet = errors.New(
		"quoted price range is not set",
	)

	ErrInvalidPricingType = errors.New(
		"invalid pricing type",
	)
)

type PaymentError struct {
	Code    string
	Message string
	Err     error
}

func (e *PaymentError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %v", e.Message, e.Err)
	}
	return e.Message
}

func (e *PaymentError) Unwrap() error {
	return e.Err
}

func NewPaymentError(code, message string, err error) *PaymentError {
	return &PaymentError{
		Code:    code,
		Message: message,
		Err:     err,
	}
}
