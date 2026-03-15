package payment

import (
	"changsure-core-service/internal/modules/booking"
	technicianservice "changsure-core-service/internal/modules/technician_service"
	"changsure-core-service/internal/modules/wallet"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"strconv"
	"time"

	"gorm.io/gorm"
)

type service struct {
	repo           Repository
	bookingRepo    booking.Repository
	paymentTxnRepo PaymentTransactionRepository
	techSvc        technicianservice.Service
	walletRepo     wallet.Repository
	omise          OmiseClient
	config         Config
	logger         Logger
	db             *gorm.DB
	feeRate        float64
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
	walletRepo wallet.Repository,
	db *gorm.DB,
	feeRate float64,
	config Config,
	logger Logger,
) (Service, error) {

	if feeRate <= 0 || feeRate >= 1 {
		feeRate = 0.05
	}
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
	if walletRepo == nil {
		return nil, fmt.Errorf("wallet repository cannot be nil")
	}
	if db == nil {
		return nil, fmt.Errorf("db cannot be nil")
	}
	if err := config.Validate(); err != nil {
		return nil, fmt.Errorf("invalid config: %w", err)
	}
	if logger == nil {
		logger = &defaultLogger{}
	}

	return &service{
		repo:           repo,
		bookingRepo:    bookingRepo,
		paymentTxnRepo: paymentTxnRepo,
		techSvc:        techSvc,
		walletRepo:     walletRepo,
		omise:          NewOmiseClient(repo, config),
		config:         config,
		logger:         logger,
		db:             db,
		feeRate:        feeRate,
	}, nil
}

func (s *service) CreatePaymentQR(ctx context.Context, req *CreateQRRequest) (*CreateQRResponse, error) {
	if req.Amount == nil {
		return nil, NewPaymentError("INVALID_AMOUNT", "amount is required", nil)
	}
	if *req.Amount <= 0 {
		return nil, ErrInvalidAmount
	}

	bkg, err := s.bookingRepo.FindByID(ctx, req.BookingID)
	if err != nil {
		return nil, err
	}
	if bkg == nil {
		return nil, NewPaymentError("BOOKING_NOT_FOUND", "booking not found", nil)
	}

	if err := ValidateAmountWithBooking(*req.Amount, bkg); err != nil {
		return nil, err
	}

	resolved, err := resolveAmountFromBooking(bkg, *req.Amount)
	if err != nil {
		return nil, err
	}

	source, err := s.omise.CreateSource(ctx, &CreateSourceRequest{
		Amount:      int64(math.Round(resolved * 100)),
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

	techName, svcName, apptDate := s.extractBookingInfo(bkg)

	return &CreateQRResponse{
		SourceID:    source.ID,
		QRCodeURI:   source.QRCodeURI,
		Amount:      resolved,
		Currency:    source.Currency,
		ExpiresAt:   source.ExpiresAt,
		Status:      PaymentStatusPending,
		QRCodeReady: source.QRReady,
		BookingID:   bkg.ID,
		Booking: BookingSnapshot{
			ID:              bkg.ID,
			BookingNumber:   bkg.BookingNumber,
			Status:          bkg.Status,
			FinalPrice:      bkg.FinalPrice,
			AppointmentDate: apptDate,
			TechnicianName:  techName,
			ServiceName:     svcName,
		},
		Description: fmt.Sprintf("Booking #%s", bkg.BookingNumber),
	}, nil
}

func (s *service) CancelPaymentQR(ctx context.Context, bookingID uint) error {
	if bookingID == 0 {
		return NewPaymentError("INVALID_BOOKING_ID", "booking ID is required", nil)
	}

	bkg, err := s.bookingRepo.FindByID(ctx, bookingID)
	if err != nil || bkg == nil {
		return NewPaymentError("BOOKING_NOT_FOUND", "booking not found", nil)
	}

	if err := s.paymentTxnRepo.CancelPendingByBookingID(ctx, bookingID); err != nil {
		return NewPaymentError("CANCEL_FAILED", "failed to cancel pending transactions", err)
	}

	s.logger.Info("payment QR cancelled", "booking_id", bookingID)
	return nil
}

func (s *service) ConfirmPaymentFromWebhook(
	ctx context.Context,
	chargeID string,
	metadata map[string]interface{},
	amount int64,
) error {

	existingTxn, _ := s.paymentTxnRepo.FindByChargeID(ctx, chargeID)
	if existingTxn != nil && existingTxn.Status == PaymentStatusSuccessful {
		s.logger.Warn("charge already processed, skipping", "charge_id", chargeID)
		return nil
	}

	rawBookingID, ok := metadata["booking_id"]
	if !ok {
		return NewPaymentError("MISSING_METADATA", "booking_id not found in metadata", nil)
	}
	bookingIDStr, ok := rawBookingID.(string)
	if !ok {
		return NewPaymentError("INVALID_METADATA", "booking_id must be string", nil)
	}
	bookingID64, err := strconv.ParseUint(bookingIDStr, 10, 64)
	if err != nil {
		return NewPaymentError("INVALID_BOOKING_ID", "booking_id is invalid", err)
	}
	bookingID := uint(bookingID64)
	amountTHB := float64(amount) / 100.0

	return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		bkg, err := s.bookingRepo.FindByIDForUpdate(ctx, bookingID)
		if err != nil || bkg == nil {
			return fmt.Errorf("booking not found: %w", err)
		}

		if bkg.Status == booking.BookingStatusCompleted {
			s.logger.Warn("booking already completed, skipping",
				"booking_id", bookingID,
				"charge_id", chargeID,
			)
			return nil
		}

		if bkg.Status != booking.BookingStatusWaitingPayment {
			s.logger.Warn("booking is not in WAITING_PAYMENT status, skipping",
				"booking_id", bookingID,
				"status", bkg.Status,
				"charge_id", chargeID,
			)
			return nil
		}

		if err := s.bookingRepo.UpdateFinalPrice(ctx, bookingID, amountTHB); err != nil {
			return fmt.Errorf("update final price: %w", err)
		}

		if err := s.bookingRepo.MarkAsPaid(ctx, bookingID); err != nil {
			return fmt.Errorf("mark as paid: %w", err)
		}

		walletTxn, err := s.walletRepo.CreditFromBooking(ctx, tx, bkg.TechnicianID, bookingID, amountTHB, s.feeRate)
		if err != nil {
			return fmt.Errorf("credit wallet: %w", err)
		}
		s.logger.Info("wallet credited",
			"technician_id", bkg.TechnicianID,
			"gross", amountTHB,
			"net", walletTxn.NetAmount,
			"fee", walletTxn.FeeAmount,
		)

		webhookJSON, _ := json.Marshal(metadata)
		webhookJSONStr := string(webhookJSON)
		now := time.Now()

		if existingTxn != nil {
			_ = s.paymentTxnRepo.MarkAsSuccessful(ctx, chargeID, map[string]interface{}{
				"charge_id": chargeID,
				"metadata":  metadata,
				"amount":    amount,
			})
		} else {
			_ = s.paymentTxnRepo.Create(ctx, &PaymentTransaction{
				BookingID:         bookingID,
				ChargeID:          &chargeID,
				Amount:            amountTHB,
				Currency:          "THB",
				PaymentMethod:     PaymentMethodPromptPay,
				Status:            PaymentStatusSuccessful,
				WebhookReceivedAt: &now,
				CompletedAt:       &now,
				RawWebhookPayload: &webhookJSONStr,
			})
		}

		s.logger.Info("payment confirmed from webhook",
			"booking_id", bookingID,
			"charge_id", chargeID,
			"amount_thb", amountTHB,
		)
		return nil
	})
}

func (s *service) HasSuccessfulPayment(ctx context.Context, bookingID uint) (bool, error) {
	bkg, err := s.bookingRepo.FindByID(ctx, bookingID)
	if err != nil {
		return false, fmt.Errorf("find booking: %w", err)
	}
	if bkg == nil {
		return false, nil
	}
	return bkg.Status == booking.BookingStatusCompleted, nil
}

func (s *service) GetPaymentSource(ctx context.Context, sourceID string) (*PaymentSource, error) {
	if sourceID == "" {
		return nil, NewPaymentError("INVALID_SOURCE_ID", "source ID is required", nil)
	}
	source, err := s.repo.GetSource(ctx, sourceID)
	if err != nil {
		return nil, s.handleRepositoryError(err)
	}
	return source, nil
}

func (s *service) ConfirmPayment(ctx context.Context, bookingID uint) error {
	return s.bookingRepo.MarkAsPaid(ctx, bookingID)
}

func (s *service) GetPaymentHistory(ctx context.Context, bookingID uint) ([]*PaymentTransaction, error) {
	return s.paymentTxnRepo.FindByBookingID(ctx, bookingID)
}

func (s *service) extractBookingInfo(bkg *booking.Booking) (techName, svcName, apptDate string) {
	if bkg.Technician.FirstName != "" {
		techName = bkg.Technician.FirstName + " " + bkg.Technician.LastName
	}
	if bkg.TechnicianService.Service.SerName != "" {
		svcName = bkg.TechnicianService.Service.SerName
	}
	if !bkg.AppointmentDate.IsZero() {
		apptDate = bkg.AppointmentDate.Format("2006-01-02")
	}
	return
}

func (s *service) handleRepositoryError(err error) error {
	if _, ok := err.(*PaymentError); ok {
		return err
	}
	return NewPaymentError("INTERNAL_ERROR", "an internal error occurred while processing payment", err)
}
