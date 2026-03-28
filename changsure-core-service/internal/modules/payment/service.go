package payment

import (
	"changsure-core-service/internal/modules/booking"
	technicianservice "changsure-core-service/internal/modules/technician_service"
	"changsure-core-service/internal/modules/wallet"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
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
	logger         *slog.Logger
	db             *gorm.DB
	feeRate        float64
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
	logger *slog.Logger,
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
		logger = slog.Default()
	}

	return &service{
		repo:           repo,
		bookingRepo:    bookingRepo,
		paymentTxnRepo: paymentTxnRepo,
		techSvc:        techSvc,
		walletRepo:     walletRepo,
		omise:          NewOmiseClient(repo, config),
		config:         config,
		logger:         logger.With("service", "payment"),
		db:             db,
		feeRate:        feeRate,
	}, nil
}

func (s *service) CreatePayment(ctx context.Context, req *CreatePaymentRequest) (*CreatePaymentResponse, error) {
	if req.Amount == nil {
		return nil, NewPaymentError("INVALID_AMOUNT", "amount is required", nil)
	}
	if *req.Amount <= 0 {
		return nil, ErrInvalidAmount
	}

	if req.IdempotencyKey != "" {
		existing, err := s.paymentTxnRepo.FindByIdempotencyKey(ctx, req.BookingID, req.IdempotencyKey)
		if err == nil && existing != nil {
			s.logger.Info("idempotent payment request", "booking_id", req.BookingID, "key", req.IdempotencyKey)
			return s.toCreatePaymentResponse(ctx, existing, nil)
		}
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
		Type:        req.Method,
		BookingID:   strconv.FormatUint(uint64(bkg.ID), 10),
		Description: fmt.Sprintf("Booking #%s", bkg.BookingNumber),
	})
	if err != nil {
		return nil, err
	}

	txn := &PaymentTransaction{
		BookingID:      bkg.ID,
		SourceID:       &source.ID,
		Amount:         resolved,
		Currency:       "THB",
		PaymentMethod:  req.Method,
		Status:         PaymentStatusPending,
		IdempotencyKey: req.IdempotencyKey,
	}
	if err := s.paymentTxnRepo.Create(ctx, txn); err != nil {
		return nil, err
	}

	return s.toCreatePaymentResponse(ctx, txn, source)
}

func (s *service) toCreatePaymentResponse(ctx context.Context, txn *PaymentTransaction, source *PaymentSource) (*CreatePaymentResponse, error) {
	bkg, err := s.bookingRepo.FindByID(ctx, txn.BookingID)
	if err != nil || bkg == nil {
		return nil, fmt.Errorf("booking not found: %w", err)
	}

	techName, svcName, apptDate := s.extractBookingInfo(bkg)

	resp := &CreatePaymentResponse{
		Method:    txn.PaymentMethod,
		Amount:    txn.Amount,
		Currency:  txn.Currency,
		Status:    txn.Status,
		BookingID: txn.BookingID,
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
	}

	if txn.SourceID != nil {
		resp.PaymentID = *txn.SourceID
	}

	if source != nil {
		resp.ExpiresAt = source.ExpiresAt
		resp.QR = &QRPaymentDetail{
			SourceID:  source.ID,
			QRCodeURI: source.QRCodeURI,
			QRReady:   source.QRReady,
		}
	}

	return resp, nil
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

	s.logger.Info("payment cancelled", "booking_id", bookingID)
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
		s.logger.Info("charge already processed, skipping", "charge_id", chargeID)
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

	if existingTxn == nil {
		pendingTxn, _ := s.paymentTxnRepo.GetLatestPendingByBookingID(ctx, bookingID)
		if pendingTxn != nil {
			existingTxn = pendingTxn
		}
	}

	return s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		bkg, err := s.bookingRepo.FindByIDForUpdate(ctx, bookingID)
		if err != nil || bkg == nil {
			return fmt.Errorf("booking not found: %w", err)
		}

		if bkg.Status == booking.BookingStatusCompleted {
			s.logger.Warn("booking already completed", "booking_id", bookingID, "charge_id", chargeID)
			return nil
		}

		if bkg.Status != booking.BookingStatusWaitingPayment {
			s.logger.Warn("booking not in WAITING_PAYMENT",
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
		eventType := "charge.complete"

		if existingTxn != nil {
			if err := s.paymentTxnRepo.MarkAsSuccessfulTx(ctx, tx, existingTxn.ID, chargeID, map[string]interface{}{
				"charge_id":           chargeID,
				"status":              PaymentStatusSuccessful,
				"webhook_received_at": now,
				"completed_at":        now,
				"raw_webhook_payload": webhookJSONStr,
				"webhook_event_type":  eventType,
			}); err != nil {
				return fmt.Errorf("mark payment as successful: %w", err)
			}
		} else {
			newTxn := &PaymentTransaction{
				BookingID:         bookingID,
				ChargeID:          &chargeID,
				Amount:            amountTHB,
				Currency:          "THB",
				PaymentMethod:     PaymentMethodPromptPay,
				Status:            PaymentStatusSuccessful,
				WebhookReceivedAt: &now,
				CompletedAt:       &now,
				RawWebhookPayload: &webhookJSONStr,
				WebhookEventType:  &eventType,
			}
			if err := tx.WithContext(ctx).Create(newTxn).Error; err != nil {
				return fmt.Errorf("create payment transaction: %w", err)
			}
		}

		s.logger.Info("payment confirmed",
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

func (s *service) HandleFailedPayment(ctx context.Context, chargeID string, metadata map[string]interface{}) error {
	now := time.Now()
	webhookJSON, _ := json.Marshal(metadata)
	webhookJSONStr := string(webhookJSON)
	eventType := "charge.fail"

	existingTxn, err := s.paymentTxnRepo.FindByChargeID(ctx, chargeID)
	if err != nil || existingTxn == nil {
		s.logger.Warn("no transaction for failed charge", "charge_id", chargeID)
		return nil
	}

	return s.paymentTxnRepo.MarkAsFailed(ctx, chargeID, map[string]interface{}{
		"charge_id":           chargeID,
		"webhook_received_at": now,
		"raw_webhook_payload": webhookJSONStr,
		"webhook_event_type":  eventType,
	})
}

func (s *service) GetBookingSummary(ctx context.Context, bookingID uint) (*BookingSummary, error) {
	if bookingID == 0 {
		return nil, fmt.Errorf("bookingID is required")
	}

	var result struct {
		ID           uint
		CustomerID   uint
		TechnicianID uint
	}
	if err := s.db.WithContext(ctx).
		Table("bookings").
		Select("id, customer_id, technician_id").
		Where("id = ?", bookingID).
		First(&result).Error; err != nil {
		return nil, fmt.Errorf("GetBookingSummary: %w", err)
	}

	return &BookingSummary{
		ID:           result.ID,
		CustomerID:   result.CustomerID,
		TechnicianID: result.TechnicianID,
	}, nil
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
