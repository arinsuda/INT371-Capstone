package payment

import (
	"context"
	"fmt"
)

type omiseClient struct {
	repo   Repository
	config Config
}

func NewOmiseClient(repo Repository, cfg Config) OmiseClient {
	return &omiseClient{
		repo:   repo,
		config: cfg,
	}
}

func (o *omiseClient) CreateSource(
	ctx context.Context,
	req *CreateSourceRequest,
) (*PaymentSource, error) {

	if req == nil {
		return nil, fmt.Errorf("nil source request")
	}

	source, err := o.repo.CreatePromptPaySource(ctx, req)
	if err != nil {
		return nil, fmt.Errorf("failed to create omise source: %w", err)
	}

	return source, nil
}
