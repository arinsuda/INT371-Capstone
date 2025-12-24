package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"time"

	"github.com/go-sql-driver/mysql"
	"golang.org/x/crypto/bcrypt"

	"changsure-core-service/internal/config"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/modules/customer"
	"changsure-core-service/internal/modules/technician"
)

type Service interface {
	Register(ctx context.Context, req RegisterRequest) (*RegisterResponse, error)
	Login(ctx context.Context, req LoginRequest) (*LoginResponse, error)
	GenerateRefreshToken(ctx context.Context, refreshToken string) (*TokenPair, error)
}

type CustomerReader interface {
	FindByEmail(ctx context.Context, email string) (*customers.Customer, error)
	FindByID(ctx context.Context, id uint) (*customers.Customer, error)
	Create(ctx context.Context, c *customers.Customer) error
}

type TechnicianReader interface {
	FindByEmail(ctx context.Context, email string) (*technician.Technician, error)
	FindByID(ctx context.Context, id uint) (*technician.Technician, error)
	Create(ctx context.Context, t *technician.Technician) error
}

type service struct {
	customers   CustomerReader
	technicians TechnicianReader
	refreshRepo RefreshTokenRepository
	cfg         *config.Config
}

func NewService(
	cRepo CustomerReader,
	tRepo TechnicianReader,
	rtRepo RefreshTokenRepository,
	cfg *config.Config,
) Service {
	return &service{
		customers:   cRepo,
		technicians: tRepo,
		refreshRepo: rtRepo,
		cfg:         cfg,
	}
}

func generateRandomTokenString() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b), nil
}

func hashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

func hashPassword(plain string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(plain), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}

func comparePassword(hash, plain string) error {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(plain))
}

func (s *service) accessTokenTTLHours() int {
	return 24
}

func (s *service) refreshTokenTTL() time.Duration {
	return 7 * 24 * time.Hour
}

func (s *service) Register(ctx context.Context, req RegisterRequest) (*RegisterResponse, error) {
	if req.Password != req.ConfirmPassword {
		return nil, errors.New("password and confirm_password do not match")
	}

	passwordHash, err := hashPassword(req.Password)
	if err != nil {
		return nil, err
	}

	var (
		userID uint
		email  = req.Email
		role   = req.Role
	)

	switch role {
	case "customer":
		c := &customers.Customer{
			FirstName:    "",
			LastName:     "",
			Email:        &email,
			PasswordHash: passwordHash,
		}
		if err := s.customers.Create(ctx, c); err != nil {

			if isDuplicateError(err) {
				return nil, ErrEmailAlreadyExists
			}
			return nil, err
		}
		userID = c.ID

	case "technician":
		t := &technician.Technician{
			FirstName:    "",
			LastName:     "",
			Email:        &email,
			PasswordHash: passwordHash,
		}
		if err := s.technicians.Create(ctx, t); err != nil {

			if isDuplicateError(err) {
				return nil, ErrEmailAlreadyExists
			}
			return nil, err
		}
		userID = t.ID

	default:
		return nil, errors.New("invalid role")
	}

	now := time.Now().Unix()

	return &RegisterResponse{
		UserID:    userID,
		Email:     email,
		Role:      role,
		CreatedAt: now,
	}, nil
}

func (s *service) Login(ctx context.Context, req LoginRequest) (*LoginResponse, error) {
	var (
		userID   uint
		role     string
		email    = req.Email
		hash     string
		username string
	)

	if c, err := s.customers.FindByEmail(ctx, req.Email); err == nil && c != nil {
		userID = c.ID
		role = "customer"
		hash = c.PasswordHash
		username = c.FirstName
	} else {
		t, err2 := s.technicians.FindByEmail(ctx, req.Email)
		if err2 != nil || t == nil {
			return nil, ErrInvalidCredentials
		}
		userID = t.ID
		role = "technician"
		hash = t.PasswordHash
		username = t.FirstName
	}

	if err := comparePassword(hash, req.Password); err != nil {
		return nil, ErrInvalidCredentials
	}

	accessToken, err := middleware.GenerateAccessToken(
		userID,
		email,
		role,
		username,
		s.cfg.JWT.Secret,
		s.accessTokenTTLHours(),
	)
	if err != nil {
		return nil, err
	}

	rawRefresh, err := generateRandomTokenString()
	if err != nil {
		return nil, err
	}
	hashRefresh := hashToken(rawRefresh)

	rt := &RefreshToken{
		UserID:    userID,
		UserRole:  role,
		TokenHash: hashRefresh,
		ExpiresAt: time.Now().Add(s.refreshTokenTTL()),
	}

	if err := s.refreshRepo.Create(ctx, rt); err != nil {
		return nil, err
	}

	now := time.Now().Unix()

	return &LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: rawRefresh,
		CreatedAt:    now,
	}, nil
}

func (s *service) GenerateRefreshToken(ctx context.Context, refreshToken string) (*TokenPair, error) {
	if refreshToken == "" {
		return nil, ErrInvalidRefreshToken
	}

	hash := hashToken(refreshToken)

	rt, err := s.refreshRepo.FindActiveByHash(ctx, hash)
	if err != nil || rt == nil {
		return nil, ErrInvalidRefreshToken
	}

	var (
		userID   = rt.UserID
		role     = rt.UserRole
		email    string
		username string
	)

	switch role {
	case "customer":
		c, err := s.customers.FindByID(ctx, userID)
		if err != nil || c == nil {
			return nil, ErrInvalidRefreshToken
		}
		if c.Email != nil {
			email = *c.Email
		}
		username = c.FirstName

	case "technician":
		t, err := s.technicians.FindByID(ctx, userID)
		if err != nil || t == nil {
			return nil, ErrInvalidRefreshToken
		}
		if t.Email != nil {
			email = *t.Email
		}
		username = t.FirstName

	default:
		return nil, ErrInvalidRefreshToken
	}

	accessToken, err := middleware.GenerateAccessToken(
		userID,
		email,
		role,
		username,
		s.cfg.JWT.Secret,
		s.accessTokenTTLHours(),
	)
	if err != nil {
		return nil, err
	}

	newRawRefresh, err := generateRandomTokenString()
	if err != nil {
		return nil, err
	}
	newHash := hashToken(newRawRefresh)

	newRT := &RefreshToken{
		UserID:    userID,
		UserRole:  role,
		TokenHash: newHash,
		ExpiresAt: time.Now().Add(s.refreshTokenTTL()),
	}

	if err := s.refreshRepo.RevokeAndReplace(ctx, rt, newRT); err != nil {
		return nil, err
	}

	return &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: newRawRefresh,
		TokenType:    "Bearer",
		ExpiresIn:    int64(s.accessTokenTTLHours() * 3600),
		Role:         role,
	}, nil
}

func isDuplicateError(err error) bool {
	var mysqlErr *mysql.MySQLError
	if errors.As(err, &mysqlErr) && mysqlErr.Number == 1062 {
		return true
	}
	return false
}
