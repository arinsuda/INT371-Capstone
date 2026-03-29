package wallet

import "errors"

var (
	ErrInsufficientBalance   = errors.New("insufficient balance")
	ErrWithdrawAmountTooLow  = errors.New("withdrawal amount below minimum")
	ErrWithdrawAmountTooHigh = errors.New("withdrawal amount exceeds maximum")
	ErrDailyLimitExceeded    = errors.New("daily withdrawal limit exceeded")
	ErrWalletFrozen          = errors.New("wallet is frozen")
	ErrWalletNotFound        = errors.New("wallet not found")
)
