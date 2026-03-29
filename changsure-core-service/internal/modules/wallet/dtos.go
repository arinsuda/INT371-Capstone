package wallet

import "time"

type WithdrawRequest struct {
	Amount         float64 `json:"amount" validate:"required,gt=0"`
	BankName       string  `json:"bank_name" validate:"required,max=100"`
	AccountNumber  string  `json:"account_number" validate:"required,max=20"`
	AccountName    string  `json:"account_name" validate:"required,max=200"`
	IdempotencyKey string  `json:"idempotency_key,omitempty"`
}

type TechInfo struct {
	TotalJobs int64
	RatingAvg float64
}

type WalletBalanceResponse struct {
	TechnicianID        uint       `json:"technician_id"`
	Balance             float64    `json:"balance"`
	PendingBalance      float64    `json:"pending_balance"`
	WithdrawableBalance float64    `json:"withdrawable_balance"`
	TotalEarned         float64    `json:"total_earned"`
	Currency            string     `json:"currency"`
	FeeRate             float64    `json:"fee_rate"`
	WalletStatus        string     `json:"wallet_status"`
	LastTransactionAt   *time.Time `json:"last_transaction_at"`
}

type WalletSummaryResponse struct {
	Balance             float64 `json:"balance"`
	WithdrawableBalance float64 `json:"withdrawable_balance"`
	TotalEarned         float64 `json:"total_earned"`
	Currency            string  `json:"currency"`
	WalletStatus        string  `json:"wallet_status"`
	TotalJobs           int64   `json:"total_jobs"`
	CompletedJobs       int64   `json:"completed_jobs"`
	CancelledJobs       int64   `json:"cancelled_jobs"`
	AverageRating       float64 `json:"average_rating"`
	ThisMonthEarned     float64 `json:"this_month_earned"`
	LastMonthEarned     float64 `json:"last_month_earned"`
	PendingBalance      float64 `json:"pending_balance"`
	AvgJobValue         float64 `json:"avg_job_value"`
}

type WithdrawResult struct {
	Withdrawal    *WithdrawalRequest `json:"withdrawal"`
	Transaction   *WalletTransaction `json:"transaction"`
	BalanceAfter  float64            `json:"balance_after"`
	Message       string             `json:"message"`
	ReferenceID   *string            `json:"reference_id,omitempty"`
	ReferenceType string             `json:"reference_type,omitempty"`
	DisplayLabel  string             `json:"display_label,omitempty"`
	Status        string             `json:"status,omitempty"`
	Metadata      JSONMap            `json:"metadata,omitempty"`
}

type JSONMap map[string]interface{}

type ListTransactionsQuery struct {
	Page     int    `query:"page"`
	Limit    int    `query:"limit"`
	Type     string `query:"type" validate:"omitempty,oneof=CREDIT DEBIT"`
	Category string `query:"category" validate:"omitempty,max=50"`
}

type PaginationMeta struct {
	Page  int   `json:"page"`
	Limit int   `json:"limit"`
	Total int64 `json:"total"`
}

type PaginatedTransactions struct {
	Items []*WalletTransaction `json:"items"`
	Meta  PaginationMeta       `json:"meta"`
}

type PaginatedWithdrawals struct {
	Items []*WithdrawalRequest `json:"items"`
	Meta  PaginationMeta       `json:"meta"`
}
