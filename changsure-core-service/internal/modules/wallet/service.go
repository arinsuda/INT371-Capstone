package wallet

import (
	"context"
	"fmt"

	"github.com/shopspring/decimal"
	"gorm.io/gorm"
)

type Service interface {
	GetBalance(ctx context.Context, technicianID uint) (*WalletBalanceResponse, error)
	GetSummary(ctx context.Context, technicianID uint, tech TechInfo) (*WalletSummaryResponse, error)
	Withdraw(ctx context.Context, technicianID uint, req WithdrawRequest) (*WithdrawResult, error)
}

type service struct {
	repo Repository
	db   *gorm.DB
}

func NewService(repo Repository, db *gorm.DB) Service {
	return &service{repo: repo, db: db}
}

func (s *service) GetBalance(ctx context.Context, technicianID uint) (*WalletBalanceResponse, error) {
	w, err := s.repo.GetBalance(ctx, technicianID)
	if err != nil {
		return nil, fmt.Errorf("get balance: %w", err)
	}

	withdrawable := calcWithdrawable(w.Balance)

	return &WalletBalanceResponse{
		TechnicianID:        w.TechnicianID,
		Balance:             w.Balance,
		WithdrawableBalance: withdrawable,
		TotalEarned:         w.TotalEarned,
		Currency:            w.Currency,
	}, nil
}

func (s *service) GetSummary(ctx context.Context, technicianID uint, tech TechInfo) (*WalletSummaryResponse, error) {
	w, err := s.repo.GetBalance(ctx, technicianID)
	if err != nil {
		return nil, fmt.Errorf("get balance: %w", err)
	}

	completed, cancelled, err := s.repo.GetJobStats(ctx, technicianID)
	if err != nil {
		return nil, fmt.Errorf("get job stats: %w", err)
	}

	withdrawable := calcWithdrawable(w.Balance)

	var avgRating float64
	if tech.RatingAvg != nil {
		avgRating = *tech.RatingAvg
	}

	return &WalletSummaryResponse{
		Balance:             w.Balance,
		WithdrawableBalance: withdrawable,
		TotalEarned:         w.TotalEarned,
		Currency:            w.Currency,
		TotalJobs:           tech.TotalJobs,
		CompletedJobs:       completed,
		CancelledJobs:       cancelled,
		AverageRating:       avgRating,
	}, nil
}

func (s *service) Withdraw(ctx context.Context, technicianID uint, req WithdrawRequest) (*WithdrawResult, error) {
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

func calcWithdrawable(balance float64) float64 {
	b := decimal.NewFromFloat(balance)
	rate := decimal.NewFromFloat(WithdrawableFeeRate)
	result := b.Mul(decimal.NewFromInt(1).Sub(rate)).RoundBank(2)
	return result.InexactFloat64()
}
