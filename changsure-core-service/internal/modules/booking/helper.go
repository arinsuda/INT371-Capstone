package booking

import (
	address "changsure-core-service/internal/modules/customer_address"
	"fmt"
	"strings"
	"time"
)

// Booking Status Constants
const (
	BookingStatusPending        = "PENDING"
	BookingStatusAccepted       = "ACCEPTED"
	BookingStatusInProgress     = "IN_PROGRESS"
	BookingStatusWaitingPayment = "WAITING_PAYMENT"
	BookingStatusCompleted      = "COMPLETED"
	BookingStatusCancelled      = "CANCELLED"
	BookingStatusRejected       = "REJECTED"

	PaymentMethodCOD = "COD"
)

// ExcludedFromAvailability statuses that don't block time slots
var ExcludedFromAvailability = []string{
	BookingStatusCancelled,
	BookingStatusRejected,
}

var allowedBookingStatuses = map[string]bool{
	BookingStatusPending:        true,
	BookingStatusAccepted:       true,
	BookingStatusInProgress:     true,
	BookingStatusWaitingPayment: true,
	BookingStatusCompleted:      true,
	BookingStatusCancelled:      true,
	BookingStatusRejected:       true,
}

// BKKLocation is the timezone for Bangkok, Thailand
var BKKLocation *time.Location

func init() {
	var err error
	BKKLocation, err = time.LoadLocation("Asia/Bangkok")
	if err != nil {
		// Fallback to UTC+7 offset if location loading fails
		BKKLocation = time.FixedZone("BKK", 7*60*60)
	}
}

// NormalizeDate returns date at midnight in BKK timezone
func NormalizeDate(t time.Time) time.Time {
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, BKKLocation)
}

// ParseDate parses date string in YYYY-MM-DD format in BKK timezone
func ParseDate(dateStr string) (time.Time, error) {
	return time.ParseInLocation("2006-01-02", dateStr, BKKLocation)
}

// FormatDate formats time to YYYY-MM-DD string
func FormatDate(t time.Time) string {
	return t.In(BKKLocation).Format("2006-01-02")
}

// IsPastDate checks if date is before today (BKK timezone)
func IsPastDate(date time.Time) bool {
	today := NormalizeDate(time.Now())
	checkDate := NormalizeDate(date)
	return checkDate.Before(today)
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
