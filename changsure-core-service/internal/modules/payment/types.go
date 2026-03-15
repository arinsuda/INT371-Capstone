package payment

import (
	"context"
	"time"

	"github.com/omise/omise-go"
)

type PaymentSource struct {
	ID       string
	Type     string
	Amount   int64
	Currency string

	Status    string
	QRCodeURI string
	QRReady   bool

	PaymentID   string
	Description string

	CreatedAt time.Time
	ExpiresAt time.Time
}

type Repository interface {
	CreatePromptPaySource(ctx context.Context, req *CreateSourceRequest) (*PaymentSource, error)
	GetSource(ctx context.Context, sourceID string) (*PaymentSource, error)
}

type Service interface {
	CreatePaymentQR(
		ctx context.Context,
		req *CreateQRRequest,
	) (*CreateQRResponse, error)
	GetPaymentSource(ctx context.Context, sourceID string) (*PaymentSource, error)

	ConfirmPayment(ctx context.Context, bookingID uint) error
	ConfirmPaymentFromWebhook(
		ctx context.Context,
		chargeID string,
		metadata map[string]interface{},
		amount int64,
	) error

	GetPaymentHistory(ctx context.Context, bookingID uint) ([]*PaymentTransaction, error)
	HasSuccessfulPayment(ctx context.Context, bookingID uint) (bool, error)
	CancelPaymentQR(ctx context.Context, bookingID uint) error
}

type CreateSourceRequest struct {
	Amount      int64
	Currency    string
	Type        string
	PaymentID   string
	BookingID   string
	Description string
}

type OmiseClient interface {
	CreateSource(
		ctx context.Context,
		req *CreateSourceRequest,
	) (*PaymentSource, error)
}

/*
FINAL mapper
*/
func FromOmiseSource(
	source *omise.Source,
	paymentID string,
	description string,
	expiryMinutes int,
) *PaymentSource {

	ps := &PaymentSource{
		ID:          source.ID,
		Type:        string(source.Type),
		Amount:      source.Amount,
		Currency:    source.Currency,
		Status:      string(source.Flow),
		PaymentID:   paymentID,
		Description: description,
		CreatedAt:   source.CreatedAt,
	}

	if source.ScannableCode != nil &&
		source.ScannableCode.Image != nil &&
		source.ScannableCode.Image.DownloadURI != "" {

		ps.QRCodeURI = source.ScannableCode.Image.DownloadURI
		ps.QRReady = true
	}

	ps.ExpiresAt = source.CreatedAt.Add(
		time.Duration(expiryMinutes) * time.Minute,
	)

	return ps
}
