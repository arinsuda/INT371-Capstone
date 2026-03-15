package resetpassword

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/pquerna/otp"
	"github.com/pquerna/otp/totp"
	"golang.org/x/crypto/bcrypt"

	"changsure-core-service/internal/modules/customer"
	"changsure-core-service/internal/modules/technician"
	"changsure-core-service/pkg/mailer"
)

const (
	otpTTL        = 5 * time.Minute
	resetTokenTTL = 15 * time.Minute
	otpDigits     = 6
	otpPeriod     = uint(300)
)

var (
	ErrEmailNotFound     = errors.New("email not found")
	ErrInvalidOTP        = errors.New("invalid or expired OTP")
	ErrInvalidToken      = errors.New("invalid or expired reset token")
	ErrPasswordMismatch  = errors.New("passwords do not match")
	ErrGoogleAccountOnly = errors.New("this account uses Google login, please sign in with Google")
)

type resetClaims struct {
	UserID uint     `json:"user_id"`
	Role   UserRole `json:"role"`
	Email  string   `json:"email"`
	jwt.RegisteredClaims
}

type Service interface {
	ForgotPassword(req ForgotPasswordRequest) (*ForgotPasswordResponse, error)
	VerifyOTP(req VerifyOTPRequest) (*VerifyOTPResponse, error)
	ResetPassword(req ResetPasswordRequest) (*ResetPasswordResponse, error)
}

type service struct {
	repo         Repository
	customerRepo customer.Repository
	techRepo     technician.Repository
	mailer       mailer.Mailer
	jwtSecret    string
	isDev        bool
}

func NewService(
	repo Repository,
	customerRepo customer.Repository,
	techRepo technician.Repository,
	m mailer.Mailer,
	jwtSecret string,
	isDev bool,
) Service {
	return &service{
		repo:         repo,
		customerRepo: customerRepo,
		techRepo:     techRepo,
		mailer:       m,
		jwtSecret:    jwtSecret,
		isDev:        isDev,
	}
}

func (s *service) ForgotPassword(req ForgotPasswordRequest) (*ForgotPasswordResponse, error) {
	userID, name, passwordHash, role, err := s.findUserByEmail(req.Email)
	if err != nil {
		return nil, err
	}

	if passwordHash == "" {
		return nil, ErrGoogleAccountOnly
	}

	if err := s.repo.InvalidateAll(req.Email, role); err != nil {
		return nil, fmt.Errorf("invalidate old otp: %w", err)
	}

	key, err := totp.Generate(totp.GenerateOpts{
		Issuer:      "ChangSure",
		AccountName: req.Email,
		Period:      otpPeriod,
		Digits:      otp.DigitsSix,
		Algorithm:   otp.AlgorithmSHA1,
	})
	if err != nil {
		return nil, fmt.Errorf("generate totp key: %w", err)
	}

	otpCode, err := totp.GenerateCode(key.Secret(), time.Now())
	if err != nil {
		return nil, fmt.Errorf("generate otp code: %w", err)
	}

	record := &PasswordResetOTP{
		ID:         uuid.New(),
		UserID:     userID,
		UserRole:   role,
		Email:      req.Email,
		TOTPSecret: key.Secret(),
		ExpiresAt:  time.Now().Add(otpTTL),
	}

	if err := s.repo.Create(record); err != nil {
		return nil, fmt.Errorf("save otp: %w", err)
	}

	if s.isDev {
		slog.Info("[DEV] TOTP generated", "email", req.Email, "otp", otpCode)

		if mailErr := s.mailer.SendOTP(req.Email, name, otpCode); mailErr != nil {
			slog.Warn("[DEV] Could not send email, OTP available in response only",
				"email", req.Email, "err", mailErr,
			)
		} else {
			slog.Info("[DEV] Email sent successfully", "email", req.Email)
		}

		return &ForgotPasswordResponse{
			Message:   "ส่งรหัส OTP ไปยัง " + req.Email + " แล้ว",
			ExpiresIn: int(otpTTL.Seconds()),
			OTP:       &otpCode,
		}, nil
	}

	if err := s.mailer.SendOTP(req.Email, name, otpCode); err != nil {
		return nil, fmt.Errorf("send otp email: %w", err)
	}

	return &ForgotPasswordResponse{
		Message:   "ส่งรหัส OTP ไปยัง " + req.Email + " แล้ว",
		ExpiresIn: int(otpTTL.Seconds()),
	}, nil
}

func (s *service) VerifyOTP(req VerifyOTPRequest) (*VerifyOTPResponse, error) {

	record, err := s.repo.FindLatestValidByEmail(req.Email)
	if err != nil {
		return nil, fmt.Errorf("find otp record: %w", err)
	}
	if record == nil {
		return nil, ErrInvalidOTP
	}

	valid, err := totp.ValidateCustom(req.OTP, record.TOTPSecret, time.Now(), totp.ValidateOpts{
		Period:    otpPeriod,
		Skew:      1,
		Digits:    otp.DigitsSix,
		Algorithm: otp.AlgorithmSHA1,
	})
	if err != nil || !valid {
		return nil, ErrInvalidOTP
	}

	if err := s.repo.MarkUsed(record.ID); err != nil {
		return nil, fmt.Errorf("mark otp used: %w", err)
	}

	token, err := s.issueResetToken(record.UserID, record.UserRole, record.Email)
	if err != nil {
		return nil, fmt.Errorf("issue reset token: %w", err)
	}

	return &VerifyOTPResponse{
		Message:    "OTP ถูกต้อง กรุณาตั้งรหัสผ่านใหม่ภายใน 15 นาที",
		ResetToken: token,
	}, nil
}

func (s *service) ResetPassword(req ResetPasswordRequest) (*ResetPasswordResponse, error) {
	claims, err := s.parseResetToken(req.ResetToken)
	if err != nil {
		return nil, ErrInvalidToken
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	if err := s.updatePassword(claims.UserID, claims.Role, string(hashed)); err != nil {
		return nil, err
	}

	return &ResetPasswordResponse{
		Message: "เปลี่ยนรหัสผ่านสำเร็จ กรุณาเข้าสู่ระบบใหม่",
	}, nil
}

func (s *service) findUserByEmail(email string) (userID uint, name string, passwordHash string, role UserRole, err error) {
	c, err := s.customerRepo.FindByEmail(context.Background(), email)
	if err != nil {
		return 0, "", "", "", fmt.Errorf("find customer: %w", err)
	}
	if c != nil {
		return c.ID, c.FirstName, c.PasswordHash, RoleCustomer, nil
	}

	t, err := s.techRepo.FindByEmail(context.Background(), email)
	if err != nil {
		return 0, "", "", "", fmt.Errorf("find technician: %w", err)
	}
	if t != nil {
		return t.ID, t.FirstName, t.PasswordHash, RoleTechnician, nil
	}

	return 0, "", "", "", ErrEmailNotFound
}

func (s *service) updatePassword(userID uint, role UserRole, hashedPassword string) error {
	switch role {
	case RoleCustomer:
		c, err := s.customerRepo.FindByID(context.Background(), userID)
		if err != nil || c == nil {
			return ErrEmailNotFound
		}
		c.PasswordHash = hashedPassword
		return s.customerRepo.Update(context.Background(), c)

	case RoleTechnician:
		t, err := s.techRepo.FindByID(context.Background(), userID)
		if err != nil || t == nil {
			return ErrEmailNotFound
		}
		t.PasswordHash = hashedPassword
		return s.techRepo.Update(context.Background(), t)
	}

	return fmt.Errorf("unknown role: %s", role)
}

func (s *service) issueResetToken(userID uint, role UserRole, email string) (string, error) {
	claims := resetClaims{
		UserID: userID,
		Role:   role,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(resetTokenTTL)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Subject:   fmt.Sprintf("%d", userID),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.jwtSecret))
}

func (s *service) parseResetToken(tokenStr string) (*resetClaims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &resetClaims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method")
		}
		return []byte(s.jwtSecret), nil
	})
	if err != nil || !token.Valid {
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*resetClaims)
	if !ok {
		return nil, ErrInvalidToken
	}
	return claims, nil
}
