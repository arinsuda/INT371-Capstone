package payment

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"gorm.io/gorm"
)

type PaymentTransactionRepository interface {
	Create(ctx context.Context, tx *PaymentTransaction) error
	FindByBookingID(ctx context.Context, bookingID uint) ([]*PaymentTransaction, error)
	FindByChargeID(ctx context.Context, chargeID string) (*PaymentTransaction, error)
	FindByIdempotencyKey(ctx context.Context, bookingID uint, key string) (*PaymentTransaction, error)
	GetLatestPendingByBookingID(ctx context.Context, bookingID uint) (*PaymentTransaction, error)
	GetLatestByBookingID(ctx context.Context, bookingID uint) (*PaymentTransaction, error)
	UpdateStatus(ctx context.Context, id uint, status string) error
	MarkAsSuccessfulTx(ctx context.Context, tx *gorm.DB, id uint, chargeID string, data map[string]interface{}) error
	MarkAsSuccessful(ctx context.Context, chargeID string, webhookData map[string]interface{}) error
	MarkAsFailed(ctx context.Context, chargeID string, webhookData map[string]interface{}) error
	CancelPendingByBookingID(ctx context.Context, bookingID uint) error
	RecordWebhookEvent(ctx context.Context, chargeID string, eventType string, eventData interface{}) error
}

type paymentTransactionRepo struct {
	db *gorm.DB
}

func NewPaymentTransactionRepository(db *gorm.DB) PaymentTransactionRepository {
	return &paymentTransactionRepo{db: db}
}

func (r *paymentTransactionRepo) Create(ctx context.Context, tx *PaymentTransaction) error {
	return r.db.WithContext(ctx).Create(tx).Error
}

func (r *paymentTransactionRepo) FindByBookingID(ctx context.Context, bookingID uint) ([]*PaymentTransaction, error) {
	var transactions []*PaymentTransaction
	err := r.db.WithContext(ctx).
		Where("booking_id = ?", bookingID).
		Order("created_at DESC").
		Find(&transactions).Error
	return transactions, err
}

func (r *paymentTransactionRepo) FindByChargeID(ctx context.Context, chargeID string) (*PaymentTransaction, error) {
	var tx PaymentTransaction
	err := r.db.WithContext(ctx).
		Where("charge_id = ?", chargeID).
		First(&tx).Error
	if err != nil {
		return nil, err
	}
	return &tx, nil
}

func (r *paymentTransactionRepo) FindByIdempotencyKey(ctx context.Context, bookingID uint, key string) (*PaymentTransaction, error) {
	if key == "" {
		return nil, nil
	}

	var tx PaymentTransaction
	err := r.db.WithContext(ctx).
		Where("booking_id = ? AND idempotency_key = ?", bookingID, key).
		First(&tx).Error
	if err != nil {
		return nil, err
	}
	return &tx, nil
}

func (r *paymentTransactionRepo) GetLatestPendingByBookingID(ctx context.Context, bookingID uint) (*PaymentTransaction, error) {
	var tx PaymentTransaction
	err := r.db.WithContext(ctx).
		Where("booking_id = ? AND status = ?", bookingID, PaymentStatusPending).
		Order("created_at DESC").
		First(&tx).Error
	if err != nil {
		return nil, err
	}
	return &tx, nil
}

func (r *paymentTransactionRepo) GetLatestByBookingID(ctx context.Context, bookingID uint) (*PaymentTransaction, error) {
	var tx PaymentTransaction
	err := r.db.WithContext(ctx).
		Where("booking_id = ?", bookingID).
		Order("created_at DESC").
		First(&tx).Error
	if err != nil {
		return nil, err
	}
	return &tx, nil
}

func (r *paymentTransactionRepo) UpdateStatus(ctx context.Context, id uint, status string) error {
	return r.db.WithContext(ctx).
		Model(&PaymentTransaction{}).
		Where("id = ?", id).
		Update("status", status).Error
}

func (r *paymentTransactionRepo) MarkAsSuccessfulTx(
	ctx context.Context,
	tx *gorm.DB,
	id uint,
	chargeID string,
	data map[string]interface{},
) error {
	if tx == nil {
		return fmt.Errorf("MarkAsSuccessfulTx requires a db transaction")
	}

	updates := map[string]interface{}{
		"charge_id":           chargeID,
		"status":              PaymentStatusSuccessful,
		"webhook_received_at": data["webhook_received_at"],
		"completed_at":        data["completed_at"],
		"raw_webhook_payload": data["raw_webhook_payload"],
		"webhook_event_type":  data["webhook_event_type"],
	}

	return tx.WithContext(ctx).
		Model(&PaymentTransaction{}).
		Where("id = ?", id).
		Updates(updates).Error
}

func (r *paymentTransactionRepo) MarkAsSuccessful(
	ctx context.Context,
	chargeID string,
	webhookData map[string]interface{},
) error {
	webhookJSON, err := json.Marshal(webhookData)
	if err != nil {
		return fmt.Errorf("failed to marshal webhook data: %w", err)
	}

	webhookJSONStr := string(webhookJSON)
	now := time.Now()

	return r.db.WithContext(ctx).
		Model(&PaymentTransaction{}).
		Where("charge_id = ?", chargeID).
		Updates(map[string]interface{}{
			"status":              PaymentStatusSuccessful,
			"webhook_received_at": now,
			"completed_at":        now,
			"raw_webhook_payload": webhookJSONStr,
		}).Error
}

func (r *paymentTransactionRepo) MarkAsFailed(
	ctx context.Context,
	chargeID string,
	webhookData map[string]interface{},
) error {
	webhookJSON, err := json.Marshal(webhookData)
	if err != nil {
		return fmt.Errorf("failed to marshal webhook data: %w", err)
	}
	webhookJSONStr := string(webhookJSON)
	now := time.Now()
	eventType := "charge.fail"

	return r.db.WithContext(ctx).
		Model(&PaymentTransaction{}).
		Where("charge_id = ?", chargeID).
		Updates(map[string]interface{}{
			"status":              PaymentStatusFailed,
			"webhook_received_at": now,
			"webhook_event_type":  &eventType,
			"raw_webhook_payload": webhookJSONStr,
		}).Error
}

func (r *paymentTransactionRepo) CancelPendingByBookingID(ctx context.Context, bookingID uint) error {
	return r.db.WithContext(ctx).
		Model(&PaymentTransaction{}).
		Where("booking_id = ? AND status = ?", bookingID, PaymentStatusPending).
		Update("status", PaymentStatusCancelled).Error
}

func (r *paymentTransactionRepo) RecordWebhookEvent(
	ctx context.Context,
	chargeID string,
	eventType string,
	eventData interface{},
) error {
	var tx PaymentTransaction
	if err := r.db.WithContext(ctx).
		Where("charge_id = ?", chargeID).
		First(&tx).Error; err != nil {
		return err
	}

	eventJSON, err := json.Marshal(eventData)
	if err != nil {
		return fmt.Errorf("failed to marshal event data: %w", err)
	}

	eventJSONStr := string(eventJSON)
	event := &PaymentEvent{
		PaymentTransactionID: tx.ID,
		EventType:            eventType,
		EventData:            &eventJSONStr,
	}

	return r.db.WithContext(ctx).Create(event).Error
}
