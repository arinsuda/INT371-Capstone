package wallet

import (
	"context"
	"fmt"
	"time"

	"github.com/shopspring/decimal"
	"gorm.io/gorm"
)

type Service interface {
	GetBalance(ctx context.Context, technicianID uint) (*WalletBalanceResponse, error)
	GetSummary(ctx context.Context, technicianID uint, tech TechInfo) (*WalletSummaryResponse, error)
	Withdraw(ctx context.Context, technicianID uint, req WithdrawRequest) (*WithdrawResult, error)
}

type Config struct {
	FeeRate          float64
	MinWithdraw      float64
	MaxWithdraw      float64
	MaxDailyWithdraw float64
}

func DefaultConfig() Config {
	return Config{
		FeeRate:          DefaultWithdrawableFeeRate,
		MinWithdraw:      MinWithdrawAmount,
		MaxWithdraw:      MaxWithdrawAmount,
		MaxDailyWithdraw: MaxDailyWithdraw,
	}
}

type service struct {
	repo   Repository
	db     *gorm.DB
	config Config
}

func NewService(repo Repository, db *gorm.DB, cfg Config) Service {
	return &service{repo: repo, db: db, config: cfg}
}

func (s *service) GetBalance(ctx context.Context, technicianID uint) (*WalletBalanceResponse, error) {
	w, err := s.repo.GetBalance(ctx, technicianID)
	if err != nil {
		return nil, fmt.Errorf("get balance: %w", err)
	}

	lastTxn, _ := s.repo.GetLastTransaction(ctx, technicianID)
	var lastTxAt *time.Time
	if lastTxn != nil {
		lastTxAt = &lastTxn.CreatedAt
	}

	withdrawable := s.calcWithdrawable(w.Balance)

	return &WalletBalanceResponse{
		TechnicianID:        w.TechnicianID,
		Balance:             w.Balance,
		PendingBalance:      0,
		WithdrawableBalance: withdrawable,
		TotalEarned:         w.TotalEarned,
		Currency:            w.Currency,
		FeeRate:             s.config.FeeRate,
		WalletStatus:        w.Status,
		LastTransactionAt:   lastTxAt,
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

	now := time.Now()
	thisMonth, _ := s.repo.GetMonthlyEarned(ctx, technicianID, now.Year(), now.Month())
	lastMonth, _ := s.repo.GetMonthlyEarned(ctx, technicianID, now.Year(), now.Month()-1)

	var avgJobValue float64
	if completed > 0 {
		avgJobValue = decimal.NewFromFloat(w.TotalEarned).
			Div(decimal.NewFromInt(completed)).
			RoundBank(2).InexactFloat64()
	}

	var avgRating float64
	if tech.RatingAvg != 0 {
		avgRating = tech.RatingAvg
	}

	withdrawable := s.calcWithdrawable(w.Balance)

	return &WalletSummaryResponse{
		Balance:             w.Balance,
		PendingBalance:      0,
		WithdrawableBalance: withdrawable,
		TotalEarned:         w.TotalEarned,
		Currency:            w.Currency,
		WalletStatus:        w.Status,
		TotalJobs:           tech.TotalJobs,
		CompletedJobs:       completed,
		CancelledJobs:       cancelled,
		AverageRating:       avgRating,
		ThisMonthEarned:     thisMonth,
		LastMonthEarned:     lastMonth,
		AvgJobValue:         avgJobValue,
	}, nil
}

func (s *service) Withdraw(ctx context.Context, technicianID uint, req WithdrawRequest) (*WithdrawResult, error) {

	if req.Amount < s.config.MinWithdraw {
		return nil, fmt.Errorf("%w: minimum is %.0f THB", ErrWithdrawAmountTooLow, s.config.MinWithdraw)
	}
	if req.Amount > s.config.MaxWithdraw {
		return nil, fmt.Errorf("%w: maximum is %.0f THB", ErrWithdrawAmountTooHigh, s.config.MaxWithdraw)
	}

	if req.IdempotencyKey != "" {
		existing, err := s.repo.FindWithdrawalByIdempotencyKey(ctx, technicianID, req.IdempotencyKey)
		if err != nil {
			return nil, fmt.Errorf("idempotency check: %w", err)
		}
		if existing != nil {

			return &WithdrawResult{
				Withdrawal:   existing,
				BalanceAfter: 0,
				Message:      fmt.Sprintf("ถอนเงิน %.2f THB (idempotent)", existing.Amount),
			}, nil
		}
	}

	dailyTotal, err := s.repo.GetDailyWithdrawalTotal(ctx, technicianID, time.Now())
	if err != nil {
		return nil, fmt.Errorf("check daily limit: %w", err)
	}
	if dailyTotal+req.Amount > s.config.MaxDailyWithdraw {
		return nil, fmt.Errorf("%w: daily limit is %.0f THB, used %.2f THB",
			ErrDailyLimitExceeded, s.config.MaxDailyWithdraw, dailyTotal)
	}

	var (
		wtx        *WalletTransaction
		withdrawal *WithdrawalRequest
	)

	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		record := WithdrawalRequest{
			BankName:      req.BankName,
			AccountNumber: req.AccountNumber,
			AccountName:   req.AccountName,
		}

		var txErr error
		wtx, withdrawal, txErr = s.repo.DebitForWithdrawal(ctx, tx, technicianID, req.Amount, record)
		return txErr
	})

	if err != nil {
		return nil, err
	}

	return &WithdrawResult{
		Withdrawal:   withdrawal,
		Transaction:  wtx,
		BalanceAfter: wtx.BalanceAfter,
		Message:      fmt.Sprintf("ถอนเงิน %.2f THB สำเร็จ", req.Amount),
	}, nil
}

func (s *service) calcWithdrawable(balance float64) float64 {
	b := decimal.NewFromFloat(balance)
	rate := decimal.NewFromFloat(s.config.FeeRate)
	result := b.Mul(decimal.NewFromInt(1).Sub(rate)).RoundBank(2)
	return result.InexactFloat64()
}
