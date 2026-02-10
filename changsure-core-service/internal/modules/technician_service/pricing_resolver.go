package technicianservice

import (
	"fmt"
)

func ResolvePaymentAmount(
	reqAmount *float64,
	pricing *TechnicianService,
) (float64, error) {

	var resolved float64

	switch pricing.PricingType {

	case "FIXED":

		if pricing.PriceFixed == nil {
			return 0, fmt.Errorf("invalid fixed pricing config")
		}

		fixed := *pricing.PriceFixed

		// client ส่ง amount มา → ต้องตรง
		if reqAmount != nil {

			if *reqAmount != fixed {
				return 0, fmt.Errorf("amount mismatch with fixed price")
			}

			resolved = *reqAmount

		} else {
			resolved = fixed
		}

	case "RANGE":

		if reqAmount == nil {
			return 0, fmt.Errorf("amount required")
		}

		if pricing.PriceMin == nil || pricing.PriceMax == nil {
			return 0, fmt.Errorf("invalid range pricing config")
		}

		a := *reqAmount

		if a < *pricing.PriceMin || a > *pricing.PriceMax {
			return 0, fmt.Errorf(
				"amount must be between %.2f - %.2f",
				*pricing.PriceMin,
				*pricing.PriceMax,
			)
		}

		resolved = a

	default:
		return 0, fmt.Errorf("unknown pricing type")
	}

	return resolved, nil
}
