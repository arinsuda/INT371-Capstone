package payment

import (
	"changsure-core-service/internal/config"
	"context"
	"fmt"

	"github.com/omise/omise-go"
	"github.com/omise/omise-go/operations"
)

type omiseRepository struct {
	client *omise.Client
	config config.OmiseConfig
}

func NewOmiseRepository(config config.OmiseConfig) (Repository, error) {
	if err := validateOmiseConfig(config); err != nil {
		return nil, fmt.Errorf("invalid omise config: %w", err)
	}

	client, err := omise.NewClient(config.PublicKey, config.SecretKey)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize omise client: %w", err)
	}

	return &omiseRepository{
		client: client,
		config: config,
	}, nil
}

func (r *omiseRepository) CreatePromptPaySource(
	ctx context.Context,
	req *CreateSourceRequest,
) (*PaymentSource, error) {

	if err := r.validateCreateSourceRequest(req); err != nil {
		return nil, err
	}

	ctx, cancel := context.WithTimeout(ctx, r.config.Timeout)
	defer cancel()

	source := &omise.Source{}

	createSourceOp := &operations.CreateSource{
		Type:     req.Type,
		Amount:   req.Amount,
		Currency: req.Currency,
	}

	if err := r.client.Do(source, createSourceOp); err != nil {
		return nil, NewPaymentError(
			"SOURCE_CREATION_FAILED",
			"failed to create promptpay source",
			err,
		)
	}

	if source.ID == "" {
		return nil, NewPaymentError(
			"INVALID_SOURCE",
			"source id is empty",
			nil,
		)
	}

	charge := &omise.Charge{}

	createChargeOp := &operations.CreateCharge{
		Amount:   req.Amount,
		Currency: req.Currency,
		Source:   source.ID,
		Metadata: map[string]interface{}{
			"booking_id": req.BookingID,
		},
	}

	if err := r.client.Do(charge, createChargeOp); err != nil {
		return nil, NewPaymentError(
			"CHARGE_CREATION_FAILED",
			"failed to create charge for source",
			err,
		)
	}

	retrieveOp := &operations.RetrieveSource{
		SourceID: source.ID,
	}

	if err := r.client.Do(source, retrieveOp); err != nil {
		return nil, NewPaymentError(
			"SOURCE_RETRIEVAL_FAILED",
			"failed to retrieve source after charge",
			err,
		)
	}

	return FromOmiseSource(
		source,
		charge.ID,
		req.PaymentID,
		req.Description,
		r.config.QRExpiryMinutes,
	), nil
}

func (r *omiseRepository) GetSource(
	ctx context.Context,
	sourceID string,
) (*PaymentSource, error) {

	if sourceID == "" {
		return nil, NewPaymentError(
			"INVALID_SOURCE_ID",
			"source id is required",
			nil,
		)
	}

	ctx, cancel := context.WithTimeout(ctx, r.config.Timeout)
	defer cancel()

	source := &omise.Source{}
	op := &operations.RetrieveSource{SourceID: sourceID}

	done := make(chan error, 1)
	go func() {
		done <- r.client.Do(source, op)
	}()

	select {
	case <-ctx.Done():
		return nil, NewPaymentError(
			"REQUEST_TIMEOUT",
			"request timeout while retrieving source",
			ctx.Err(),
		)

	case err := <-done:
		if err != nil {
			return nil, NewPaymentError(
				"SOURCE_RETRIEVAL_FAILED",
				"failed to retrieve source",
				err,
			)
		}
	}

	return FromOmiseSource(
		source,
		"",
		"",
		"",
		r.config.QRExpiryMinutes,
	), nil
}

func (r *omiseRepository) validateCreateSourceRequest(req *CreateSourceRequest) error {
	if req == nil {
		return NewPaymentError("INVALID_REQUEST", "request cannot be nil", nil)
	}
	if req.Amount <= 0 {
		return ErrInvalidAmount
	}
	if req.Currency == "" {
		req.Currency = r.config.Currency
	}
	if req.Type == "" {
		req.Type = "promptpay"
	}
	return nil
}

func validateOmiseConfig(config config.OmiseConfig) error {
	if config.PublicKey == "" {
		return fmt.Errorf("public key is required")
	}
	if config.SecretKey == "" {
		return fmt.Errorf("secret key is required")
	}
	if config.Timeout <= 0 {
		return fmt.Errorf("timeout must be greater than 0")
	}
	return nil
}
