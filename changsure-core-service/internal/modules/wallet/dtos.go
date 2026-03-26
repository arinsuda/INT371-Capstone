package wallet

type WithdrawRequest struct {
	Amount        float64 `json:"amount"         validate:"required,gt=0"`
	BankName      string  `json:"bank_name"      validate:"required,max=100"`
	AccountNumber string  `json:"account_number" validate:"required,max=20"`
	AccountName   string  `json:"account_name"   validate:"required,max=200"`
}

type TechInfo struct {
	TotalJobs int64
	RatingAvg float64
}

type WalletBalanceResponse struct {
	TechnicianID        uint    `json:"technician_id"`
	Balance             float64 `json:"balance"`
	WithdrawableBalance float64 `json:"withdrawable_balance"`
	TotalEarned         float64 `json:"total_earned"`
	Currency            string  `json:"currency"`
}

type WalletSummaryResponse struct {
	Balance             float64 `json:"balance"`
	WithdrawableBalance float64 `json:"withdrawable_balance"`
	TotalEarned         float64 `json:"total_earned"`
	Currency            string  `json:"currency"`

	TotalJobs     int64    `json:"total_jobs"`
	CompletedJobs int64   `json:"completed_jobs"`
	CancelledJobs int64   `json:"cancelled_jobs"`
	AverageRating float64 `json:"average_rating"`
}

type WithdrawResult struct {
	Transaction  *WalletTransaction `json:"transaction"`
	BalanceAfter float64            `json:"balance_after"`
	Message      string             `json:"message"`
}
