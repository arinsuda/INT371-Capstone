package customerbooking

type CreateBookingRequest struct {
	CustomerID      uint   `json:"-" form:"-"`
	TechnicianID    uint   `json:"technician_id" validate:"required" form:"technician_id"`
	ServiceID       uint   `json:"service_id" validate:"required" form:"service_id"`
	AddressID       uint   `json:"address_id" validate:"required" form:"address_id"`
	TimeSlotID      uint   `json:"time_slot_id" validate:"required" form:"time_slot_id"`
	AppointmentDate string `json:"appointment_date" validate:"required" form:"appointment_date"`
	CustomerNote    string `json:"customer_note" form:"customer_note"`

	ImageURLs []string `json:"image_urls" form:"-"`
}

type CheckAvailabilityQuery struct {
	TechnicianID uint   `query:"technician_id" validate:"required"`
	Date         string `query:"date" validate:"required,datetime=2006-01-02"`
}

type TimeSlotAvailability struct {
	ID          uint   `json:"id"`
	Label       string `json:"label"`
	IsAvailable bool   `json:"is_available"`
}

type CancelBookingRequest struct {
	Reason string `json:"reason" validate:"max=255"`
}

type ListBookingsQuery struct {
	Status    string `query:"status" validate:"omitempty"`
	StartDate string `query:"start_date" validate:"omitempty,datetime=2006-01-02"`
	EndDate   string `query:"end_date" validate:"omitempty,datetime=2006-01-02"`

	Page  int `query:"page" validate:"omitempty,min=1"`
	Limit int `query:"limit" validate:"omitempty,min=1,max=100"`
}
