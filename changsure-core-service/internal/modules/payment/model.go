package payment

import (
	"time"
)

type PaymentTransaction struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	BookingID uint    `gorm:"not null;index" json:"booking_id"`
	ChargeID  *string `gorm:"uniqueIndex;size:100" json:"charge_id,omitempty"`
	SourceID  *string `gorm:"index;size:100" json:"source_id,omitempty"`

	Amount        float64 `gorm:"type:decimal(10,2);not null" json:"amount"`
	Currency      string  `gorm:"size:3;default:THB" json:"currency"`
	PaymentMethod string  `gorm:"size:50;default:promptpay" json:"payment_method"`

	Status      string  `gorm:"size:50;default:pending;index" json:"status"`
	OmiseStatus *string `gorm:"size:50" json:"omise_status,omitempty"`

	WebhookReceivedAt *time.Time `json:"webhook_received_at,omitempty"`
	WebhookEventType  *string    `gorm:"size:100" json:"webhook_event_type,omitempty"`

	RawWebhookPayload *string `gorm:"type:json" json:"raw_webhook_payload,omitempty"`
	ErrorMessage      *string `gorm:"type:text" json:"error_message,omitempty"`

	CompletedAt *time.Time `json:"completed_at,omitempty"`
}

func (PaymentTransaction) TableName() string {
	return "payment_transactions"
}

type PaymentEvent struct {
	ID                   uint      `gorm:"primaryKey" json:"id"`
	PaymentTransactionID uint      `gorm:"not null;index" json:"payment_transaction_id"`
	EventType            string    `gorm:"size:100;not null;index" json:"event_type"`
	EventData            *string   `gorm:"type:json" json:"event_data,omitempty"`
	CreatedAt            time.Time `json:"created_at"`

	PaymentTransaction PaymentTransaction `gorm:"foreignKey:PaymentTransactionID" json:"-"`
}

func (PaymentEvent) TableName() string {
	return "payment_events"
}

const (
	PaymentStatusPending    = "pending"
	PaymentStatusSuccessful = "successful"
	PaymentStatusFailed     = "failed"
	PaymentStatusRefunded   = "refunded"
	PaymentStatusExpired    = "expired"
)

const (
	PaymentMethodPromptPay     = "promptpay"
	PaymentMethodCreditCard    = "credit_card"
	PaymentMethodRabbitLinePay = "rabbit_linepay"
)
