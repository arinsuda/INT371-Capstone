package booking

import (
	address "changsure-core-service/internal/modules/customer_address"
	"fmt"
	"strings"
)

var allowedBookingStatuses = map[string]bool{
	BookingStatusPending:        true,
	BookingStatusAccepted:       true,
	BookingStatusInProgress:     true,
	BookingStatusWaitingPayment: true,
	BookingStatusCompleted:      true,
	BookingStatusCancelled:      true,
}

func ParseStatusFilter(raw string) ([]string, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}

	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))

	seen := make(map[string]bool)
	for _, p := range parts {
		s := strings.ToUpper(strings.TrimSpace(p))
		if s == "" {
			continue
		}
		if !allowedBookingStatuses[s] {
			return nil, fmt.Errorf("invalid status: %s", s)
		}
		if !seen[s] {
			seen[s] = true
			out = append(out, s)
		}
	}

	if len(out) == 0 {
		return nil, nil
	}
	return out, nil
}

func FormatAddressSnapshot(addr *address.CustomerAddress) string {
	subName := "-"
	distName := "-"
	provName := "-"
	postal := "-"

	if addr.SubDistrict != nil {
		subName = addr.SubDistrict.NameTH
		postal = addr.SubDistrict.PostalCode
	}
	if addr.District != nil {
		distName = addr.District.NameTH
	}
	if addr.Province != nil {
		provName = addr.Province.NameTH
	}

	return fmt.Sprintf("%s หมู่บ้าน %s ซอย %s ถนน %s แขวง %s เขต %s จ. %s %s",
		GetValue(addr.HouseNumber),
		GetValue(addr.Village),
		GetValue(addr.Soi),
		GetValue(addr.Road),
		subName,
		distName,
		provName,
		postal,
	)
}

func GetValue(s *string) string {
	if s == nil {
		return "-"
	}
	return *s
}
