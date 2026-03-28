package payment

import "time"

type CreatePaymentRequest struct {
	BookingID   uint     `json:"booking_id"   validate:"required"`
	Amount      *float64 `json:"amount"`
	Method      string   `json:"method"       validate:"required,oneof=promptpay credit_card rabbit_linepay"`
	Currency    string   `json:"currency,omitempty" validate:"omitempty,iso4217"`
	Description string   `json:"description,omitempty" validate:"omitempty,max=500"`

	IdempotencyKey string `json:"idempotency_key,omitempty" validate:"omitempty,max=64"`
}

func (r *CreatePaymentRequest) ToAmountSatang() int64 {
	if r.Amount == nil {
		return 0
	}
	return int64(*r.Amount * 100)
}

type CreatePaymentResponse struct {
	PaymentID   string          `json:"payment_id"`
	Method      string          `json:"method"`
	Amount      float64         `json:"amount"`
	Currency    string          `json:"currency"`
	ExpiresAt   time.Time       `json:"expires_at"`
	Status      string          `json:"status"`
	BookingID   uint            `json:"booking_id"`
	Booking     BookingSnapshot `json:"booking"`
	Description string          `json:"description,omitempty"`

	QR *QRPaymentDetail `json:"qr,omitempty"`
}

type QRPaymentDetail struct {
	SourceID  string `json:"source_id"`
	QRCodeURI string `json:"qr_code_uri,omitempty"`
	QRReady   bool   `json:"qr_ready"`
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

type PaymentStatusResponse struct {
	PaymentID string  `json:"payment_id"`
	BookingID uint    `json:"booking_id"`
	Status    string  `json:"status"`
	Amount    float64 `json:"amount"`
	Currency  string  `json:"currency"`
	Method    string  `json:"method"`

	CompletedAt       *time.Time `json:"completed_at,omitempty"`
	WebhookReceivedAt *time.Time `json:"webhook_received_at,omitempty"`
}

type ErrorResponse struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

type SimulatePaymentRequest struct {
	PaymentID string  `json:"payment_id"  validate:"required"`
	BookingID uint    `json:"booking_id"  validate:"required"`
	Amount    float64 `json:"amount"      validate:"required,gt=0"`
}

type CreateQRRequest = CreatePaymentRequest

type CreateQRResponse = CreatePaymentResponse
