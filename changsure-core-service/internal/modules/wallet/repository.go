package wallet

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/shopspring/decimal"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Repository interface {
	GetOrCreate(ctx context.Context, tx *gorm.DB, technicianID uint) (*TechnicianWallet, error)
	CreditFromBooking(ctx context.Context, tx *gorm.DB, technicianID uint, bookingID uint, grossAmount float64, feeRate float64) (*WalletTransaction, error)
	DebitForWithdrawal(ctx context.Context, tx *gorm.DB, technicianID uint, amount float64, req WithdrawalRequest) (*WalletTransaction, *WithdrawalRequest, error)
	GetBalance(ctx context.Context, technicianID uint) (*TechnicianWallet, error)
	GetLastTransaction(ctx context.Context, technicianID uint) (*WalletTransaction, error)
	ListTransactions(ctx context.Context, technicianID uint, q ListTransactionsQuery) ([]*WalletTransaction, int64, error)
	ListWithdrawals(ctx context.Context, technicianID uint, page, limit int) ([]*WithdrawalRequest, int64, error)
	GetJobStats(ctx context.Context, technicianID uint) (completed int64, cancelled int64, err error)
	GetMonthlyEarned(ctx context.Context, technicianID uint, year int, month time.Month) (float64, error)
	GetDailyWithdrawalTotal(ctx context.Context, technicianID uint, date time.Time) (float64, error)
	FindWithdrawalByIdempotencyKey(ctx context.Context, technicianID uint, key string) (*WithdrawalRequest, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) GetOrCreate(ctx context.Context, tx *gorm.DB, technicianID uint) (*TechnicianWallet, error) {
	db := r.resolveDB(tx)

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
			Status:       WalletStatusActive,
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

	if w.Status == WalletStatusFrozen {
		return nil, ErrWalletFrozen
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

	refType := TxRefTypeBooking
	refID := fmt.Sprintf("%d", bookingID)

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
		ReferenceID:   &refID,
		ReferenceType: &refType,
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
) (*WalletTransaction, *WithdrawalRequest, error) {
	if tx == nil {
		return nil, nil, fmt.Errorf("DebitForWithdrawal must run inside a DB transaction")
	}
	if amount <= 0 {
		return nil, nil, fmt.Errorf("withdrawal amount must be greater than 0")
	}

	w, err := r.GetOrCreate(ctx, tx, technicianID)
	if err != nil {
		return nil, nil, err
	}

	if w.Status == WalletStatusFrozen {
		return nil, nil, ErrWalletFrozen
	}

	balance := decimal.NewFromFloat(w.Balance)
	withdrawal := decimal.NewFromFloat(amount)

	if balance.LessThan(withdrawal) {
		return nil, nil, ErrInsufficientBalance
	}

	balanceBefore := w.Balance
	balanceAfter := balance.Sub(withdrawal).RoundBank(2)
	balanceAfterF64 := balanceAfter.InexactFloat64()

	if err := tx.WithContext(ctx).
		Model(&TechnicianWallet{}).
		Where("id = ?", w.ID).
		Update("balance", balanceAfterF64).Error; err != nil {
		return nil, nil, fmt.Errorf("update wallet balance: %w", err)
	}

	now := time.Now()
	req.WalletID = w.ID
	req.TechnicianID = technicianID
	req.Amount = amount
	req.Status = WithdrawalStatusCompleted
	req.ProcessedAt = &now
	if err := tx.WithContext(ctx).Create(&req).Error; err != nil {
		return nil, nil, fmt.Errorf("create withdrawal request: %w", err)
	}

	note := fmt.Sprintf("ถอนเงินไปยัง %s %s (%s)", req.BankName, req.AccountNumber, req.AccountName)
	refType := TxRefTypeWithdrawal
	refID := fmt.Sprintf("%d", req.ID)
	label := fmt.Sprintf("ถอนเงิน — %s %s", req.BankName, req.AccountNumber)

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
		ReferenceID:   &refID,
		ReferenceType: &refType,
		DisplayLabel:  &label,
		Note:          &note,
	}
	if err := tx.WithContext(ctx).Create(wtx).Error; err != nil {
		return nil, nil, fmt.Errorf("create wallet transaction: %w", err)
	}

	return wtx, &req, nil
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
			Status:       WalletStatusActive,
		}, nil
	}
	return &w, err
}

func (r *repository) GetLastTransaction(ctx context.Context, technicianID uint) (*WalletTransaction, error) {
	var w TechnicianWallet
	if err := r.db.WithContext(ctx).
		Where("technician_id = ?", technicianID).
		First(&w).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}

	var txn WalletTransaction
	err := r.db.WithContext(ctx).
		Where("wallet_id = ?", w.ID).
		Order("created_at DESC").
		First(&txn).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &txn, err
}

func (r *repository) ListTransactions(ctx context.Context, technicianID uint, q ListTransactionsQuery) ([]*WalletTransaction, int64, error) {
	page, limit := normalizePagination(q.Page, q.Limit)
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

	base := r.db.WithContext(ctx).Model(&WalletTransaction{}).Where("wallet_id = ?", w.ID)

	if q.Type != "" {
		base = base.Where("type = ?", q.Type)
	}
	if q.Category != "" {
		base = base.Where("category = ?", q.Category)
	}

	var total int64
	base.Count(&total)

	var txns []*WalletTransaction
	err := base.Order("created_at DESC").Limit(limit).Offset(offset).Find(&txns).Error
	return txns, total, err
}

func (r *repository) ListWithdrawals(ctx context.Context, technicianID uint, page, limit int) ([]*WithdrawalRequest, int64, error) {
	page, limit = normalizePagination(page, limit)
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

func (r *repository) GetJobStats(ctx context.Context, technicianID uint) (int64, int64, error) {
	var completed, cancelled int64

	r.db.WithContext(ctx).Table("bookings").
		Where("technician_id = ? AND status = ?", technicianID, "COMPLETED").
		Count(&completed)

	r.db.WithContext(ctx).Table("bookings").
		Where("technician_id = ? AND status IN ?", technicianID, []string{"CANCELLED", "REJECTED"}).
		Count(&cancelled)

	return completed, cancelled, nil
}

func (r *repository) GetMonthlyEarned(ctx context.Context, technicianID uint, year int, month time.Month) (float64, error) {
	var w TechnicianWallet
	if err := r.db.WithContext(ctx).
		Where("technician_id = ?", technicianID).
		First(&w).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return 0, nil
		}
		return 0, err
	}

	start := time.Date(year, month, 1, 0, 0, 0, 0, time.UTC)
	end := start.AddDate(0, 1, 0)

	var total float64
	err := r.db.WithContext(ctx).
		Model(&WalletTransaction{}).
		Select("COALESCE(SUM(net_amount), 0)").
		Where("wallet_id = ? AND type = ? AND category = ? AND created_at >= ? AND created_at < ?",
			w.ID, TxTypeCredit, TxCategoryJobPayment, start, end).
		Scan(&total).Error

	return total, err
}

func (r *repository) GetDailyWithdrawalTotal(ctx context.Context, technicianID uint, date time.Time) (float64, error) {
	start := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)
	end := start.AddDate(0, 0, 1)

	var total float64
	err := r.db.WithContext(ctx).
		Model(&WithdrawalRequest{}).
		Select("COALESCE(SUM(amount), 0)").
		Where("technician_id = ? AND status = ? AND created_at >= ? AND created_at < ?",
			technicianID, WithdrawalStatusCompleted, start, end).
		Scan(&total).Error

	return total, err
}

func (r *repository) FindWithdrawalByIdempotencyKey(ctx context.Context, technicianID uint, key string) (*WithdrawalRequest, error) {

	var w WithdrawalRequest
	err := r.db.WithContext(ctx).
		Where("technician_id = ? AND note LIKE ?", technicianID, "%"+key+"%").
		Order("created_at DESC").
		First(&w).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &w, err
}

func (r *repository) resolveDB(tx *gorm.DB) *gorm.DB {
	if tx != nil {
		return tx
	}
	return r.db
}

func normalizePagination(page, limit int) (int, int) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	return page, limit
}
