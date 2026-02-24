package technicianbooking

import "fmt"

type UpdateBookingStatusRequest struct {
	Action string `json:"action" validate:"required"`
	Reason string `json:"reason,omitempty" validate:"max=255"`
}

var allowedActions = map[string]bool{
	"ACCEPT":   true,
	"REJECT":   true,
	"START":    true,
	"COMPLETE": true,
}

func (r *UpdateBookingStatusRequest) Validate() error {
	if r.Action == "" {
		return fmt.Errorf("action is required")
	}
	if !allowedActions[r.Action] {
		return fmt.Errorf("invalid action: %s, allowed: ACCEPT, REJECT, START, COMPLETE", r.Action)
	}
	if len(r.Reason) > 255 {
		return fmt.Errorf("reason must not exceed 255 characters")
	}
	return nil
}

type ListBookingsQuery struct {
	Status    string `query:"status"     validate:"omitempty"`
	StartDate string `query:"start_date" validate:"omitempty,datetime=2006-01-02"`
	EndDate   string `query:"end_date"   validate:"omitempty,datetime=2006-01-02"`
	TimeSlot  *uint  `query:"timeslot"`
	Page      int    `query:"page"       validate:"omitempty,min=1"`
	Limit     int    `query:"limit"      validate:"omitempty,min=1,max=100"`
}
