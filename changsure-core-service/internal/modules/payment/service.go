package payment

import (
	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/internal/modules/technician_service"
	"math"

	"context"
	"encoding/json"
	"fmt"
	"log"
	"strconv"
	"time"

	"gorm.io/gorm"
)

type service struct {
	repo           Repository
	bookingRepo    booking.Repository
	paymentTxnRepo PaymentTransactionRepository
	techSvc        technicianservice.Service
	omise          OmiseClient
	config         Config
	logger         Logger
}

type Logger interface {
	Info(msg string, fields ...interface{})
	Error(msg string, fields ...interface{})
	Warn(msg string, fields ...interface{})
}

type defaultLogger struct{}

func (l *defaultLogger) Info(msg string, fields ...interface{}) {
	log.Printf("[INFO] %s %v", msg, fields)
}

func (l *defaultLogger) Error(msg string, fields ...interface{}) {
	log.Printf("[ERROR] %s %v", msg, fields)
}

func (l *defaultLogger) Warn(msg string, fields ...interface{}) {
	log.Printf("[WARN] %s %v", msg, fields)
}

func NewService(
	repo Repository,
	bookingRepo booking.Repository,
	paymentTxnRepo PaymentTransactionRepository,
	techSvc technicianservice.Service,
	config Config,
	logger Logger,
) (Service, error) {

	if repo == nil {
		return nil, fmt.Errorf("repository cannot be nil")
	}

	if bookingRepo == nil {
		return nil, fmt.Errorf("booking repository cannot be nil")
	}

	if paymentTxnRepo == nil {
		return nil, fmt.Errorf("payment transaction repository cannot be nil")
	}

	if techSvc == nil {
		return nil, fmt.Errorf("technician service cannot be nil")
	}

	if err := config.Validate(); err != nil {
		return nil, fmt.Errorf("invalid config: %w", err)
	}

	if logger == nil {
		logger = &defaultLogger{}
	}

	omiseClient := NewOmiseClient(repo, config)

	return &service{
		repo:           repo,
		bookingRepo:    bookingRepo,
		paymentTxnRepo: paymentTxnRepo,
		techSvc:        techSvc,
		omise:          omiseClient,
		config:         config,
		logger:         logger,
	}, nil
}

func (s *service) CreatePaymentQR(
	ctx context.Context,
	req *CreateQRRequest,
) (*CreateQRResponse, error) {

	bkg, err := s.bookingRepo.FindByID(ctx, req.BookingID)
	if err != nil {
		return nil, err
	}

	if err := ValidateAmountWithBooking(*req.Amount, bkg); err != nil {
		return nil, err
	}

	resolved, err := resolveAmountFromBooking(bkg, *req.Amount)
	if err != nil {
		return nil, err
	}

	satang := int64(math.Round(resolved * 100))

	source, err := s.omise.CreateSource(ctx, &CreateSourceRequest{
		Amount:      satang,
		Currency:    "THB",
		Type:        "promptpay",
		BookingID:   strconv.FormatUint(uint64(bkg.ID), 10),
		Description: fmt.Sprintf("Booking #%s", bkg.BookingNumber),
	})
	if err != nil {
		return nil, err
	}

	txn := &PaymentTransaction{
		BookingID: bkg.ID,
		SourceID:  &source.ID,
		Amount:    resolved,
		Currency:  "THB",
		Status:    PaymentStatusPending,
	}

	if err := s.paymentTxnRepo.Create(ctx, txn); err != nil {
		return nil, err
	}

	return &CreateQRResponse{
		BookingID:   bkg.ID,
		Amount:      resolved,
		QRCodeURI:   source.QRCodeURI,
		Status:      PaymentStatusPending,
		QRCodeReady: source.QRReady,
	}, nil
}

func (s *service) GetPaymentSource(ctx context.Context, sourceID string) (*PaymentSource, error) {
	if sourceID == "" {
		return nil, NewPaymentError("INVALID_SOURCE_ID", "source ID is required", nil)
	}

	s.logger.Info("retrieving payment source", "source_id", sourceID)

	source, err := s.repo.GetSource(ctx, sourceID)
	if err != nil {
		s.logger.Error("failed to retrieve payment source",
			"error", err,
			"source_id", sourceID,
		)
		return nil, s.handleRepositoryError(err)
	}

	s.logger.Info("payment source retrieved successfully", "source_id", sourceID)
	return source, nil
}

func (s *service) ConfirmPayment(ctx context.Context, bookingID uint) error {
	return s.bookingRepo.MarkAsPaid(ctx, bookingID)
}

func (s *service) handleRepositoryError(err error) error {

	if _, ok := err.(*PaymentError); ok {
		return err
	}

	return NewPaymentError(
		"INTERNAL_ERROR",
		"an internal error occurred while processing payment",
		err,
	)
}

func (s *service) ConfirmPaymentFromWebhook(
	ctx context.Context,
	chargeID string,
	metadata map[string]interface{},
	amount int64,
) error {

	existingTxn, err := s.paymentTxnRepo.FindByChargeID(ctx, chargeID)
	if err == nil && existingTxn != nil {
		if existingTxn.Status == PaymentStatusSuccessful {
			s.logger.Warn("charge already processed, skipping",
				"charge_id", chargeID,
				"booking_id", existingTxn.BookingID,
			)
			return nil
		}
	}

	rawBookingID, ok := metadata["booking_id"]
	if !ok {
		return NewPaymentError(
			"MISSING_METADATA",
			"booking_id not found in metadata",
			nil,
		)
	}

	bookingIDStr, ok := rawBookingID.(string)
	if !ok {
		return NewPaymentError(
			"INVALID_METADATA",
			"booking_id must be string",
			nil,
		)
	}

	bookingID, err := strconv.ParseUint(bookingIDStr, 10, 64)
	if err != nil {
		return NewPaymentError(
			"INVALID_BOOKING_ID",
			"booking_id is invalid",
			err,
		)
	}

	if existingTxn != nil {

		webhookData := map[string]interface{}{
			"charge_id": chargeID,
			"metadata":  metadata,
			"amount":    amount,
		}

		if err := s.paymentTxnRepo.MarkAsSuccessful(ctx, chargeID, webhookData); err != nil {
			s.logger.Error("failed to update payment transaction", "error", err)
		}
	} else {

		amountTHB := float64(amount) / 100.0
		webhookJSON, _ := json.Marshal(metadata)
		webhookJSONStr := string(webhookJSON)
		now := time.Now()

		newTxn := &PaymentTransaction{
			BookingID:         uint(bookingID),
			ChargeID:          &chargeID,
			Amount:            amountTHB,
			Currency:          "THB",
			PaymentMethod:     PaymentMethodPromptPay,
			Status:            PaymentStatusSuccessful,
			WebhookReceivedAt: &now,
			CompletedAt:       &now,
			RawWebhookPayload: &webhookJSONStr,
		}

		if err := s.paymentTxnRepo.Create(ctx, newTxn); err != nil {
			s.logger.Error("failed to create payment transaction from webhook", "error", err)
		}
	}

	if err := s.bookingRepo.MarkAsPaid(ctx, uint(bookingID)); err != nil {
		return err
	}

	s.logger.Info("payment confirmed from webhook",
		"booking_id", bookingID,
		"charge_id", chargeID,
		"amount", amount,
	)

	return nil
}

func (s *service) GetPaymentHistory(ctx context.Context, bookingID uint) ([]*PaymentTransaction, error) {
	return s.paymentTxnRepo.FindByBookingID(ctx, bookingID)
}

func (s *service) HasSuccessfulPayment(ctx context.Context, bookingID uint) (bool, error) {
	transactions, err := s.paymentTxnRepo.FindByBookingID(ctx, bookingID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return false, nil
		}
		return false, err
	}

	for _, txn := range transactions {
		if txn.Status == PaymentStatusSuccessful {
			return true, nil
		}
	}

	return false, nil
}
