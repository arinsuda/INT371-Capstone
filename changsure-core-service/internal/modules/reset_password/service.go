package resetpassword

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"changsure-core-service/internal/modules/customer"
	"changsure-core-service/internal/modules/technician"
	"changsure-core-service/pkg/mailer"
)

const (
	otpTTL        = 5 * time.Minute
	resetTokenTTL = 15 * time.Minute
	otpLength     = 6
)

var (
	ErrEmailNotFound     = errors.New("email not found")
	ErrInvalidOTP        = errors.New("invalid or expired OTP")
	ErrInvalidToken      = errors.New("invalid or expired reset token")
	ErrPasswordMismatch  = errors.New("passwords do not match")
	ErrGoogleAccountOnly = errors.New("this account uses Google login, please sign in with Google") // เพิ่ม
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
) Service {
	return &service{
		repo:         repo,
		customerRepo: customerRepo,
		techRepo:     techRepo,
		mailer:       m,
		jwtSecret:    jwtSecret,
	}
}

func (s *service) ForgotPassword(req ForgotPasswordRequest) (*ForgotPasswordResponse, error) {
	userID, name, passwordHash, err := s.findUserByEmail(req.Email, req.Role)
	if err != nil {
		return nil, err
	}

	if passwordHash == "" {
		return nil, ErrGoogleAccountOnly
	}

	if err := s.repo.InvalidateAll(req.Email, req.Role); err != nil {
		return nil, fmt.Errorf("invalidate old otp: %w", err)
	}

	otp, err := generateOTP(otpLength)
	if err != nil {
		return nil, fmt.Errorf("generate otp: %w", err)
	}

	record := &PasswordResetOTP{
		ID:        uuid.New(),
		UserID:    userID,
		UserRole:  req.Role,
		Email:     req.Email,
		OTP:       otp,
		ExpiresAt: time.Now().Add(otpTTL),
	}

	if err := s.repo.Create(record); err != nil {
		return nil, fmt.Errorf("save otp: %w", err)
	}

	if s.isDev {
		return &ForgotPasswordResponse{
			Message:   "[DEV] OTP สำหรับ " + req.Email,
			ExpiresIn: int(otpTTL.Seconds()),
			OTP:       &otp,
		}, nil
	}

	if err := s.mailer.SendOTP(req.Email, name, otp); err != nil {
		return nil, fmt.Errorf("send otp email: %w", err)
	}

	return &ForgotPasswordResponse{
		Message:   "ส่งรหัส OTP ไปยัง " + req.Email + " แล้ว",
		ExpiresIn: int(otpTTL.Seconds()),
	}, nil
}

func (s *service) VerifyOTP(req VerifyOTPRequest) (*VerifyOTPResponse, error) {
	record, err := s.repo.FindValidOTP(req.Email, req.Role, req.OTP)
	if err != nil {
		return nil, fmt.Errorf("find otp: %w", err)
	}
	if record == nil {
		return nil, ErrInvalidOTP
	}

	if err := s.repo.MarkUsed(record.ID); err != nil {
		return nil, fmt.Errorf("mark otp used: %w", err)
	}

	token, err := s.issueResetToken(record.UserID, req.Role, req.Email)
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

func (s *service) findUserByEmail(email string, role UserRole) (uint, string, string, error) {
	switch role {
	case RoleCustomer:
		c, err := s.customerRepo.FindByEmail(context.Background(), email)
		if err != nil {
			return 0, "", "", fmt.Errorf("find customer: %w", err)
		}
		if c == nil {
			return 0, "", "", ErrEmailNotFound
		}
		return c.ID, c.FirstName, c.PasswordHash, nil

	case RoleTechnician:
		t, err := s.techRepo.FindByEmail(context.Background(), email)
		if err != nil {
			return 0, "", "", fmt.Errorf("find technician: %w", err)
		}
		if t == nil {
			return 0, "", "", ErrEmailNotFound
		}
		return t.ID, t.FirstName, t.PasswordHash, nil
	}

	return 0, "", "", fmt.Errorf("unknown role: %s", role)
}

func (s *service) updatePassword(userID uint, role UserRole, hashedPassword string) error {
	switch role {
	case RoleCustomer:
		c, err := s.customerRepo.FindByID(nil, userID)
		if err != nil || c == nil {
			return ErrEmailNotFound
		}
		c.PasswordHash = hashedPassword
		return s.customerRepo.Update(nil, c)

	case RoleTechnician:
		t, err := s.techRepo.FindByID(nil, userID)
		if err != nil || t == nil {
			return ErrEmailNotFound
		}
		t.PasswordHash = hashedPassword
		return s.techRepo.Update(nil, t)
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

func generateOTP(length int) (string, error) {
	const digits = "0123456789"
	result := make([]byte, length)
	for i := range result {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(digits))))
		if err != nil {
			return "", err
		}
		result[i] = digits[n.Int64()]
	}
	return string(result), nil
}
