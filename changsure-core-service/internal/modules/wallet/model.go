package wallet

import "time"

type TechnicianWallet struct {
	ID           uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	TechnicianID uint      `gorm:"not null;uniqueIndex"     json:"technician_id"`
	Balance      float64   `gorm:"type:decimal(12,2);not null;default:0" json:"balance"`
	TotalEarned  float64   `gorm:"type:decimal(12,2);not null;default:0" json:"total_earned"`
	Currency     string    `gorm:"type:varchar(3);default:THB"          json:"currency"`
	CreatedAt    time.Time `gorm:"autoCreateTime"                       json:"created_at"`
	UpdatedAt    time.Time `gorm:"autoUpdateTime"                       json:"updated_at"`
}

func (TechnicianWallet) TableName() string { return "technician_wallets" }

type WalletTransaction struct {
	ID            uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	WalletID      uint      `gorm:"not null;index"           json:"wallet_id"`
	BookingID     *uint     `gorm:"index"                    json:"booking_id,omitempty"`
	Type          string    `gorm:"type:varchar(10);not null" json:"type"`
	Category      string    `gorm:"type:varchar(50);not null" json:"category"`
	GrossAmount   float64   `gorm:"type:decimal(12,2);not null" json:"gross_amount"`
	FeeAmount     float64   `gorm:"type:decimal(12,2);not null;default:0" json:"fee_amount"`
	FeeRate       float64   `gorm:"type:decimal(5,4);not null;default:0" json:"fee_rate"` // snapshot อัตราตอนนั้น
	NetAmount     float64   `gorm:"type:decimal(12,2);not null" json:"net_amount"`
	BalanceBefore float64   `gorm:"type:decimal(12,2);not null" json:"balance_before"`
	BalanceAfter  float64   `gorm:"type:decimal(12,2);not null" json:"balance_after"`
	Note          *string   `gorm:"type:text"                json:"note,omitempty"`
	CreatedAt     time.Time `gorm:"autoCreateTime"           json:"created_at"`

	Wallet TechnicianWallet `gorm:"foreignKey:WalletID" json:"-"`
}

func (WalletTransaction) TableName() string { return "wallet_transactions" }

// WithdrawalRequest — บันทึกคำขอถอนเงิน (เสมือน)
type WithdrawalRequest struct {
	ID            uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	WalletID      uint      `gorm:"not null;index"           json:"wallet_id"`
	TechnicianID  uint      `gorm:"not null;index"           json:"technician_id"`
	Amount        float64   `gorm:"type:decimal(12,2);not null" json:"amount"`
	BankName      string    `gorm:"type:varchar(100)"        json:"bank_name"`
	AccountNumber string    `gorm:"type:varchar(20)"         json:"account_number"`
	AccountName   string    `gorm:"type:varchar(200)"        json:"account_name"`
	Status        string    `gorm:"type:varchar(20);default:completed" json:"status"` // completed (เสมือนจ่ายทันที)
	Note          *string   `gorm:"type:text"                json:"note,omitempty"`
	ProcessedAt   time.Time `gorm:"autoCreateTime"           json:"processed_at"`
	CreatedAt     time.Time `gorm:"autoCreateTime"           json:"created_at"`
}

func (WithdrawalRequest) TableName() string { return "withdrawal_requests" }

const (
	TxTypeCredit = "CREDIT"
	TxTypeDebit  = "DEBIT"
)

const (
	TxCategoryJobPayment = "JOB_PAYMENT"
	TxCategoryWithdrawal = "WITHDRAWAL"
	TxCategoryRefund     = "REFUND"
	TxCategoryAdjustment = "ADJUSTMENT"
)

func Models() []interface{} {
	return []interface{}{
		&TechnicianWallet{},
		&WalletTransaction{},
		&WithdrawalRequest{},
	}
}
