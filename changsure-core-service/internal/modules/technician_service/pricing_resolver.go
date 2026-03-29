package technicianservice

import (
	"errors"
	"fmt"
)

var (
	ErrInvalidPricingConfig = errors.New("invalid pricing configuration")
	ErrAmountMismatch       = errors.New("amount does not match fixed price")
	ErrAmountRequired       = errors.New("amount is required for RANGE pricing")
	ErrAmountOutOfRange     = errors.New("amount is outside the allowed price range")
	ErrUnknownPricingType   = errors.New("unknown pricing type")
)

func ResolvePaymentAmount(reqAmount *float64, pricing *TechnicianService) (float64, error) {
	switch pricing.PricingType {
	case "FIXED":
		return resolveFixed(reqAmount, pricing)
	case "RANGE":
		return resolveRange(reqAmount, pricing)
	default:
		return 0, ErrUnknownPricingType
	}
}

func resolveFixed(reqAmount *float64, pricing *TechnicianService) (float64, error) {
	if pricing.PriceFixed == nil {
		return 0, fmt.Errorf("%w: price_fixed is nil", ErrInvalidPricingConfig)
	}
	fixed := *pricing.PriceFixed
	if reqAmount == nil {
		return fixed, nil
	}
	if *reqAmount != fixed {
		return 0, fmt.Errorf("%w: expected %.2f, got %.2f", ErrAmountMismatch, fixed, *reqAmount)
	}
	return fixed, nil
}

func resolveRange(reqAmount *float64, pricing *TechnicianService) (float64, error) {
	if reqAmount == nil {
		return 0, ErrAmountRequired
	}
	if pricing.PriceMin == nil || pricing.PriceMax == nil {
		return 0, fmt.Errorf("%w: price_min or price_max is nil", ErrInvalidPricingConfig)
	}
	amount := *reqAmount
	if amount < *pricing.PriceMin || amount > *pricing.PriceMax {
		return 0, fmt.Errorf("%w: %.2f is not between %.2f and %.2f",
			ErrAmountOutOfRange, amount, *pricing.PriceMin, *pricing.PriceMax)
	}
	return amount, nil
}
