package wallet

import (
	"context"
	"fmt"

	"gorm.io/gorm"
)

type Service interface {
	Withdraw(ctx context.Context, technicianID uint, req WithdrawRequest) (*WithdrawResult, error)
}

type WithdrawRequest struct {
	Amount        float64 `json:"amount"         validate:"required,gt=0"`
	BankName      string  `json:"bank_name"      validate:"required,max=100"`
	AccountNumber string  `json:"account_number" validate:"required,max=20"`
	AccountName   string  `json:"account_name"   validate:"required,max=200"`
}

type WithdrawResult struct {
	Transaction  *WalletTransaction `json:"transaction"`
	BalanceAfter float64            `json:"balance_after"`
	Message      string             `json:"message"`
}

type service struct {
	repo Repository
	db   *gorm.DB
}

func NewService(repo Repository, db *gorm.DB) Service {
	return &service{repo: repo, db: db}
}

func (s *service) Withdraw(
	ctx context.Context,
	technicianID uint,
	req WithdrawRequest,
) (*WithdrawResult, error) {
	if req.Amount <= 0 {
		return nil, fmt.Errorf("amount must be greater than 0")
	}

	var wtx *WalletTransaction

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		withdrawal := WithdrawalRequest{
			BankName:      req.BankName,
			AccountNumber: req.AccountNumber,
			AccountName:   req.AccountName,
		}

		var err error
		wtx, err = s.repo.DebitForWithdrawal(ctx, tx, technicianID, req.Amount, withdrawal)
		return err
	})
	if err != nil {
		return nil, err
	}

	return &WithdrawResult{
		Transaction:  wtx,
		BalanceAfter: wtx.BalanceAfter,
		Message:      fmt.Sprintf("ถอนเงิน %.2f THB สำเร็จ (เสมือน)", req.Amount),
	}, nil
}
