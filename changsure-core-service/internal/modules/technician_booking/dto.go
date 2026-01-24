package technicianbooking

type RejectBookingRequest struct {
	Reason string `json:"reason,omitempty" validate:"max=255"`
}

type ListBookingsQuery struct {
	Status    string `query:"status" validate:"omitempty"`
	StartDate string `query:"start_date" validate:"omitempty,datetime=2006-01-02"`
	EndDate   string `query:"end_date" validate:"omitempty,datetime=2006-01-02"`

	Page  int `query:"page" validate:"omitempty,min=1"`
	Limit int `query:"limit" validate:"omitempty,min=1,max=100"`
}
