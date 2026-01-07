package booking

type CreateBookingRequest struct {
	CustomerID          uint   `json:"customer_id" form:"customer_id"`
	TechnicianID        uint   `json:"technician_id" validate:"required" form:"technician_id"`
	TechnicianServiceID uint   `json:"technician_service_id" validate:"required" form:"technician_service_id"`
	AddressID           uint   `json:"address_id" validate:"required" form:"address_id"`
	TimeSlotID          uint   `json:"time_slot_id" validate:"required" form:"time_slot_id"`
	AppointmentDate     string `json:"appointment_date" validate:"required" form:"appointment_date"`
	CustomerNote        string `json:"customer_note" form:"customer_note"`

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
