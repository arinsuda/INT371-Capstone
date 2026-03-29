package technicianbooking

import "fmt"

type UpdateBookingStatusRequest struct {
	Status string `json:"status" validate:"required"`
	Reason string `json:"reason,omitempty" validate:"max=255"`
}

var allowedTransitions = map[string][]string{
	BookingStatusAccepted:       {BookingStatusPending},
	BookingStatusRejected:       {BookingStatusPending, BookingStatusAccepted},
	BookingStatusInProgress:     {BookingStatusAccepted},
	BookingStatusWaitingPayment: {BookingStatusInProgress},
}

var ValidTransitionStatuses = func() []string {
	s := make([]string, 0, len(allowedTransitions))
	for k := range allowedTransitions {
		s = append(s, k)
	}
	return s
}()

func (r *UpdateBookingStatusRequest) Validate() error {
	if r.Status == "" {
		return fmt.Errorf("status is required")
	}
	if _, ok := allowedTransitions[r.Status]; !ok {
		return fmt.Errorf("invalid status: %s", r.Status)
	}
	if len(r.Reason) > 255 {
		return fmt.Errorf("reason must not exceed 255 characters")
	}
	return nil
}

func (r *UpdateBookingStatusRequest) IsAllowedFrom(currentStatus string) bool {
	sources, ok := allowedTransitions[r.Status]
	if !ok {
		return false
	}
	for _, s := range sources {
		if s == currentStatus {
			return true
		}
	}
	return false
}

const (
	BookingStatusPending        = "PENDING"
	BookingStatusAccepted       = "ACCEPTED"
	BookingStatusRejected       = "REJECTED"
	BookingStatusInProgress     = "IN_PROGRESS"
	BookingStatusWaitingPayment = "WAITING_PAYMENT"
	BookingStatusCompleted      = "COMPLETED"
	BookingStatusCancelled      = "CANCELLED"
)

type ListBookingsQuery struct {
	Status    string `query:"status"     validate:"omitempty"`
	StartDate string `query:"start_date" validate:"omitempty,datetime=2006-01-02"`
	EndDate   string `query:"end_date"   validate:"omitempty,datetime=2006-01-02"`
	TimeSlot  *uint  `query:"timeslot"`
	Page      int    `query:"page"       validate:"omitempty,min=1"`
	Limit     int    `query:"limit"      validate:"omitempty,min=1,max=100"`
}
