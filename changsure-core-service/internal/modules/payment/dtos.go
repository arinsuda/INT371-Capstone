package payment

import (
	"time"
)

type CreateQRRequest struct {
	BookingID   uint     `json:"booking_id" validate:"required"`
	Amount      *float64 `json:"amount"`
	Currency    string   `json:"currency,omitempty" validate:"omitempty,iso4217"`
	Description string   `json:"description,omitempty" validate:"omitempty,max=500"`
}

type CreateQRResponse struct {
	SourceID  string    `json:"source_id"`
	QRCodeURI string    `json:"qr_code_uri,omitempty"`
	Amount    float64   `json:"amount"`
	Currency  string    `json:"currency"`
	ExpiresAt time.Time `json:"expires_at"`
	Status    string    `json:"status"`

	BookingID uint            `json:"booking_id"`
	Booking   BookingSnapshot `json:"booking"`

	Description string `json:"description,omitempty"`
	QRCodeReady bool   `json:"qr_code_ready"`
}

type ErrorResponse struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

func (r *CreateQRRequest) ToAmount() int64 {
	return int64(*r.Amount * 100)
}

type BookingSnapshot struct {
	ID              uint     `json:"id"`
	BookingNumber   string   `json:"booking_number"`
	Status          string   `json:"status"`
	FinalPrice      *float64 `json:"final_price,omitempty"`
	AppointmentDate string   `json:"appointment_date"`
	TechnicianName  string   `json:"technician_name"`
	ServiceName     string   `json:"service_name"`
}
