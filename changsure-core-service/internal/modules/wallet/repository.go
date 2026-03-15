package wallet

import (
	"context"
	"errors"
	"fmt"

	"github.com/shopspring/decimal"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Repository interface {
	GetOrCreate(ctx context.Context, tx *gorm.DB, technicianID uint) (*TechnicianWallet, error)
	CreditFromBooking(ctx context.Context, tx *gorm.DB, technicianID uint, bookingID uint, grossAmount float64, feeRate float64) (*WalletTransaction, error)
	DebitForWithdrawal(ctx context.Context, tx *gorm.DB, technicianID uint, amount float64, req WithdrawalRequest) (*WalletTransaction, error)
	GetBalance(ctx context.Context, technicianID uint) (*TechnicianWallet, error)
	ListTransactions(ctx context.Context, technicianID uint, page, limit int) ([]*WalletTransaction, int64, error)
	ListWithdrawals(ctx context.Context, technicianID uint, page, limit int) ([]*WithdrawalRequest, int64, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) GetOrCreate(ctx context.Context, tx *gorm.DB, technicianID uint) (*TechnicianWallet, error) {
	db := tx
	if db == nil {
		db = r.db
	}

	var w TechnicianWallet
	err := db.WithContext(ctx).
		Clauses(clause.Locking{Strength: "UPDATE"}).
		Where("technician_id = ?", technicianID).
		First(&w).Error

	if errors.Is(err, gorm.ErrRecordNotFound) {
		w = TechnicianWallet{
			TechnicianID: technicianID,
			Balance:      0,
			TotalEarned:  0,
			Currency:     "THB",
		}
		if createErr := db.WithContext(ctx).Create(&w).Error; createErr != nil {
			return nil, fmt.Errorf("create wallet: %w", createErr)
		}
		return &w, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get wallet: %w", err)
	}
	return &w, nil
}

func (r *repository) CreditFromBooking(
	ctx context.Context,
	tx *gorm.DB,
	technicianID uint,
	bookingID uint,
	grossAmount float64,
	feeRate float64,
) (*WalletTransaction, error) {
	if tx == nil {
		return nil, fmt.Errorf("CreditFromBooking must run inside a DB transaction")
	}

	gross := decimal.NewFromFloat(grossAmount)
	rate := decimal.NewFromFloat(feeRate)

	fee := gross.Mul(rate).RoundBank(2)
	net := gross.Sub(fee).RoundBank(2)

	w, err := r.GetOrCreate(ctx, tx, technicianID)
	if err != nil {
		return nil, err
	}

	balance := decimal.NewFromFloat(w.Balance)
	balanceBefore := w.Balance
	balanceAfter := balance.Add(net).RoundBank(2)

	if err := tx.WithContext(ctx).
		Model(&TechnicianWallet{}).
		Where("id = ?", w.ID).
		Updates(map[string]any{
			"balance":      balanceAfter.InexactFloat64(),
			"total_earned": gorm.Expr("total_earned + ?", net.InexactFloat64()),
		}).Error; err != nil {
		return nil, fmt.Errorf("update wallet balance: %w", err)
	}

	feeF64 := fee.InexactFloat64()
	netF64 := net.InexactFloat64()
	balanceAfterF64 := balanceAfter.InexactFloat64()

	note := fmt.Sprintf("หักค่าคอม %.0f%% (%.2f THB)", feeRate*100, feeF64)
	wtx := &WalletTransaction{
		WalletID:      w.ID,
		BookingID:     &bookingID,
		Type:          TxTypeCredit,
		Category:      TxCategoryJobPayment,
		GrossAmount:   grossAmount,
		FeeAmount:     feeF64,
		FeeRate:       feeRate,
		NetAmount:     netF64,
		BalanceBefore: balanceBefore,
		BalanceAfter:  balanceAfterF64,
		Note:          &note,
	}
	if err := tx.WithContext(ctx).Create(wtx).Error; err != nil {
		return nil, fmt.Errorf("create wallet transaction: %w", err)
	}

	return wtx, nil
}

func (r *repository) DebitForWithdrawal(
	ctx context.Context,
	tx *gorm.DB,
	technicianID uint,
	amount float64,
	req WithdrawalRequest,
) (*WalletTransaction, error) {
	if tx == nil {
		return nil, fmt.Errorf("DebitForWithdrawal must run inside a DB transaction")
	}
	if amount <= 0 {
		return nil, fmt.Errorf("withdrawal amount must be greater than 0")
	}

	w, err := r.GetOrCreate(ctx, tx, technicianID)
	if err != nil {
		return nil, err
	}

	balance := decimal.NewFromFloat(w.Balance)
	withdrawal := decimal.NewFromFloat(amount)

	if balance.LessThan(withdrawal) {
		return nil, fmt.Errorf("insufficient balance: have %.2f, need %.2f", w.Balance, amount)
	}

	balanceBefore := w.Balance
	balanceAfter := balance.Sub(withdrawal).RoundBank(2)
	balanceAfterF64 := balanceAfter.InexactFloat64()

	if err := tx.WithContext(ctx).
		Model(&TechnicianWallet{}).
		Where("id = ?", w.ID).
		Update("balance", balanceAfterF64).Error; err != nil {
		return nil, fmt.Errorf("update wallet balance: %w", err)
	}

	req.WalletID = w.ID
	req.TechnicianID = technicianID
	req.Amount = amount
	req.Status = "completed"
	if err := tx.WithContext(ctx).Create(&req).Error; err != nil {
		return nil, fmt.Errorf("create withdrawal request: %w", err)
	}

	note := fmt.Sprintf("ถอนเงินไปยัง %s %s (%s)", req.BankName, req.AccountNumber, req.AccountName)
	wtx := &WalletTransaction{
		WalletID:      w.ID,
		Type:          TxTypeDebit,
		Category:      TxCategoryWithdrawal,
		GrossAmount:   amount,
		FeeAmount:     0,
		FeeRate:       0,
		NetAmount:     amount,
		BalanceBefore: balanceBefore,
		BalanceAfter:  balanceAfterF64,
		Note:          &note,
	}
	if err := tx.WithContext(ctx).Create(wtx).Error; err != nil {
		return nil, fmt.Errorf("create wallet transaction: %w", err)
	}

	return wtx, nil
}

func (r *repository) GetBalance(ctx context.Context, technicianID uint) (*TechnicianWallet, error) {
	var w TechnicianWallet
	err := r.db.WithContext(ctx).
		Where("technician_id = ?", technicianID).
		First(&w).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return &TechnicianWallet{
			TechnicianID: technicianID,
			Balance:      0,
			TotalEarned:  0,
			Currency:     "THB",
		}, nil
	}
	return &w, err
}

func (r *repository) ListTransactions(ctx context.Context, technicianID uint, page, limit int) ([]*WalletTransaction, int64, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	var w TechnicianWallet
	if err := r.db.WithContext(ctx).
		Where("technician_id = ?", technicianID).
		First(&w).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return []*WalletTransaction{}, 0, nil
		}
		return nil, 0, err
	}

	var total int64
	r.db.WithContext(ctx).Model(&WalletTransaction{}).
		Where("wallet_id = ?", w.ID).Count(&total)

	var txns []*WalletTransaction
	err := r.db.WithContext(ctx).
		Where("wallet_id = ?", w.ID).
		Order("created_at DESC").
		Limit(limit).Offset(offset).
		Find(&txns).Error

	return txns, total, err
}

func (r *repository) ListWithdrawals(ctx context.Context, technicianID uint, page, limit int) ([]*WithdrawalRequest, int64, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	var total int64
	r.db.WithContext(ctx).Model(&WithdrawalRequest{}).
		Where("technician_id = ?", technicianID).Count(&total)

	var items []*WithdrawalRequest
	err := r.db.WithContext(ctx).
		Where("technician_id = ?", technicianID).
		Order("created_at DESC").
		Limit(limit).Offset(offset).
		Find(&items).Error

	return items, total, err
}
