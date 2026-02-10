package payment

import (
	"changsure-core-service/internal/modules/booking"
	"net/http"

	"github.com/go-playground/validator/v10"
)

func resolveAmountFromBooking(b *booking.Booking, amount float64) (float64, error) {
	switch b.PricingType {
	case "FIXED":
		return *b.QuotedPriceFixed, nil
	case "RANGE":
		return amount, nil
	default:
		return 0, NewPaymentError(
			"INVALID_PRICING_TYPE",
			"invalid pricing type",
			nil,
		)
	}
}

func ValidateAmountWithBooking(amount float64, b *booking.Booking) error {
	switch b.PricingType {

	case "FIXED":
		if b.QuotedPriceFixed == nil {
			return NewPaymentError(
				"FIXED_PRICE_NOT_SET",
				"quoted fixed price is not set",
				nil,
			)
		}

		if amount != *b.QuotedPriceFixed {
			return NewPaymentError(
				"AMOUNT_NOT_MATCH_FIXED_PRICE",
				"amount must equal quoted fixed price",
				nil,
			)
		}

	case "RANGE":
		if b.QuotedPriceMin == nil || b.QuotedPriceMax == nil {
			return NewPaymentError(
				"RANGE_PRICE_NOT_SET",
				"quoted price range is not set",
				nil,
			)
		}

		if amount < *b.QuotedPriceMin || amount > *b.QuotedPriceMax {
			return NewPaymentError(
				"AMOUNT_OUT_OF_RANGE",
				"amount must be within quoted price range",
				nil,
			)
		}

	default:
		return NewPaymentError(
			"INVALID_PRICING_TYPE",
			"invalid pricing type",
			nil,
		)
	}

	return nil
}

var badRequestErrors = map[string]bool{
	"INVALID_REQUEST":              true,
	"INVALID_PAYMENT_ID":           true,
	"INVALID_AMOUNT":               true,
	"AMOUNT_OUT_OF_RANGE":          true,
	"AMOUNT_NOT_MATCH_FIXED_PRICE": true,
	"FIXED_PRICE_NOT_SET":          true,
	"RANGE_PRICE_NOT_SET":          true,
	"INVALID_PRICING_TYPE":         true,
	"VALIDATION_ERROR":             true,
	"INVALID_SOURCE_ID":            true,
}

func (h *Handler) mapErrorCodeToHTTPStatus(code string) int {
	if badRequestErrors[code] {
		return http.StatusBadRequest
	}

	switch code {
	case "PROVIDER_UNAVAILABLE":
		return http.StatusServiceUnavailable
	case "REQUEST_TIMEOUT":
		return http.StatusGatewayTimeout
	default:
		return http.StatusInternalServerError
	}
}

func (h *Handler) formatValidationError(fieldErr validator.FieldError) string {
	switch fieldErr.Tag() {
	case "required":
		return "this field is required"
	case "min":
		return "value is too short"
	case "max":
		return "value is too long"
	case "gt":
		return "value must be greater than " + fieldErr.Param()
	case "gte":
		return "value must be greater than or equal to " + fieldErr.Param()
	case "lt":
		return "value must be less than " + fieldErr.Param()
	case "lte":
		return "value must be less than or equal to " + fieldErr.Param()
	default:
		return "validation failed"
	}
}
