package emailverification

import (
	"context"
	"crypto/rand"
	"fmt"
	"log/slog"
	"math/big"
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/pkg/mailer"
)

const (
	otpTTL         = 5 * time.Minute
	resendCooldown = 60 * time.Second
	maxAttempts    = 5
)

type UserVerifier interface {
	MarkEmailVerified(ctx context.Context, email string) error
}

type Service interface {
	IssueOTP(ctx context.Context, userID uint, email, role string) (*SendOTPResponse, error)
	VerifyOTP(ctx context.Context, email, role, otpInput string) error
}

type service struct {
	repo             Repository
	mailer           mailer.Mailer
	customerVerifier UserVerifier
	techVerifier     UserVerifier
	isDev            bool
}

func NewService(
	repo Repository,
	m mailer.Mailer,
	customerVerifier UserVerifier,
	techVerifier UserVerifier,
	isDev bool,
) Service {
	return &service{
		repo:             repo,
		mailer:           m,
		customerVerifier: customerVerifier,
		techVerifier:     techVerifier,
		isDev:            isDev,
	}
}

func (s *service) IssueOTP(ctx context.Context, userID uint, email, role string) (*SendOTPResponse, error) {

	latest, err := s.repo.FindLatestPending(ctx, email, role)
	if err != nil {
		return nil, fmt.Errorf("FindLatestPending: %w", err)
	}
	if latest != nil && latest.ResendAt != nil && time.Now().Before(*latest.ResendAt) {
		remaining := int(time.Until(*latest.ResendAt).Seconds())
		return nil, appErrors.NewConflict(
			fmt.Sprintf("%s — รอ %d วินาที", ErrResendTooSoon.Error(), remaining),
		)
	}

	if err := s.repo.DeletePendingByEmail(ctx, email, role); err != nil {
		return nil, fmt.Errorf("DeletePendingByEmail: %w", err)
	}

	otpCode, err := generateOTP(6)
	if err != nil {
		return nil, fmt.Errorf("generateOTP: %w", err)
	}

	resendAt := time.Now().Add(resendCooldown)
	record := &EmailOTP{
		Email:     email,
		Role:      role,
		UserID:    userID,
		OTP:       otpCode,
		ExpiresAt: time.Now().Add(otpTTL),
		ResendAt:  &resendAt,
	}
	if err := s.repo.Create(ctx, record); err != nil {
		return nil, fmt.Errorf("Create OTP: %w", err)
	}

	resp := &SendOTPResponse{
		ResendIn: int(resendCooldown.Seconds()),
	}

	if s.isDev {
		slog.Info("[DEV] Email verification OTP", "email", email, "otp", otpCode, "role", role)

		if s.mailer != nil {
			if mailErr := s.mailer.SendEmailVerification(email, otpCode); mailErr != nil {
				slog.Error("[DEV] Failed to send email", "email", email, "err", mailErr)
			} else {
				slog.Info("[DEV] Verification email sent successfully", "email", email)
			}
		} else {
			slog.Warn("[DEV] Mailer is nil — skipping email send")
		}

		resp.Message = "[DEV] OTP อยู่ใน response นี้"
		resp.OTP = &otpCode
		return resp, nil
	}

	if s.mailer == nil {
		return nil, fmt.Errorf("mailer not configured")
	}
	if err := s.mailer.SendEmailVerification(email, otpCode); err != nil {
		return nil, fmt.Errorf("send OTP email: %w", err)
	}

	resp.Message = "ส่ง OTP ไปที่ email เรียบร้อยแล้ว กรุณาตรวจสอบ inbox"
	return resp, nil
}

func (s *service) VerifyOTP(ctx context.Context, email, role, otpInput string) error {
	record, err := s.repo.FindLatestPending(ctx, email, role)
	if err != nil {
		return fmt.Errorf("FindLatestPending: %w", err)
	}
	if record == nil {
		return appErrors.NewNotFound(ErrOTPNotFound.Error())
	}
	if record.AttemptCount >= maxAttempts {
		return appErrors.NewConflict(ErrOTPMaxAttempts.Error())
	}
	if time.Now().After(record.ExpiresAt) {
		return appErrors.NewConflict(ErrOTPExpired.Error())
	}

	if err := s.repo.IncrementAttempt(ctx, record.ID); err != nil {
		return fmt.Errorf("IncrementAttempt: %w", err)
	}

	if record.OTP != otpInput {
		remaining := maxAttempts - record.AttemptCount - 1
		if remaining <= 0 {
			return appErrors.NewConflict(ErrOTPMaxAttempts.Error())
		}
		return appErrors.NewConflict(
			fmt.Sprintf("%s — เหลืออีก %d ครั้ง", ErrOTPInvalid.Error(), remaining),
		)
	}

	if err := s.repo.MarkVerified(ctx, record.ID); err != nil {
		return fmt.Errorf("MarkVerified: %w", err)
	}

	switch role {
	case "customer":
		if s.customerVerifier != nil {
			return s.customerVerifier.MarkEmailVerified(ctx, email)
		}
	case "technician":
		if s.techVerifier != nil {
			return s.techVerifier.MarkEmailVerified(ctx, email)
		}
	}

	return nil
}

func generateOTP(digits int) (string, error) {
	max := new(big.Int).Exp(big.NewInt(10), big.NewInt(int64(digits)), nil)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%0*d", digits, n), nil
}
