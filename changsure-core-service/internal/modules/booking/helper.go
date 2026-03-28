package booking

import (
	address "changsure-core-service/internal/modules/customer_address"
	bookingconst "changsure-core-service/internal/shared"
	"context"
	"fmt"
	"strings"
	"time"
)

const (
	BookingStatusPending        = bookingconst.StatusPending
	BookingStatusAccepted       = bookingconst.StatusAccepted
	BookingStatusInProgress     = bookingconst.StatusInProgress
	BookingStatusWaitingPayment = bookingconst.StatusWaitingPayment
	BookingStatusCompleted      = bookingconst.StatusCompleted
	BookingStatusCancelled      = bookingconst.StatusCancelled
	BookingStatusRejected       = bookingconst.StatusRejected
	BookingStatusPaid           = bookingconst.StatusPaid
	PaymentMethodCOD            = "COD"
)

var ExcludedFromAvailability = []string{
	BookingStatusPending,
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

var BKKLocation *time.Location

func init() {
	var err error
	BKKLocation, err = time.LoadLocation("Asia/Bangkok")
	if err != nil {

		BKKLocation = time.FixedZone("BKK", 7*60*60)
	}
}

func NormalizeDate(t time.Time) time.Time {
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, BKKLocation)
}

func ParseDate(dateStr string) (time.Time, error) {
	return time.ParseInLocation("2006-01-02", dateStr, BKKLocation)
}

func FormatDate(t time.Time) string {
	return t.In(BKKLocation).Format("2006-01-02")
}

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

func (r *repository) hydrateTechnicians(ctx context.Context, bookings []Booking) {
	if len(bookings) == 0 {
		return
	}
	ids := make([]uint, len(bookings))
	for i, b := range bookings {
		ids[i] = b.TechnicianID
	}

	var snaps []TechnicianSnapshot
	r.db.WithContext(ctx).
		Table("technicians").
		Select(`
			id, first_name, last_name, phone, avatar_url,
			COALESCE((
				SELECT ROUND(AVG(rv.rating), 2)
				FROM reviews rv JOIN bookings bk ON bk.id = rv.booking_id
				WHERE bk.technician_id = technicians.id
			), 0) AS rating_avg,
			COALESCE((
				SELECT COUNT(*) FROM bookings bk
				WHERE bk.technician_id = technicians.id AND bk.status = 'COMPLETED'
			), 0) AS total_jobs
		`).
		Where("id IN ?", ids).
		Scan(&snaps)

	snapMap := make(map[uint]TechnicianSnapshot, len(snaps))
	for _, s := range snaps {
		snapMap[s.ID] = s
	}
	for i := range bookings {
		bookings[i].Technician = snapMap[bookings[i].TechnicianID]
	}
}
