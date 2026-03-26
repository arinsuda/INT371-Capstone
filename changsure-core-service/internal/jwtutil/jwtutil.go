package jwtutil

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const (
	ScopePreVerified = "pre_verified"
	RoleCustomer     = "customer"
	RoleTechnician   = "technician"
	RoleAdmin        = "admin"

	TokenTypeAccess  = "access"
	TokenTypeRefresh = "refresh"

	DefaultAccessTTL  = 15 * time.Minute
	DefaultRefreshTTL = 7 * 24 * time.Hour
)

var (
	ErrTokenInvalid = errors.New("invalid token")
	ErrTokenExpired = errors.New("token expired")
)

type Claims struct {
	jwt.RegisteredClaims
	UserID             uint   `json:"user_id"`
	Email              string `json:"email"`
	Role               string `json:"role"`
	VerificationStatus string `json:"verification_status"`
	TokenType          string `json:"token_type"`
	Scope              string `json:"scope,omitempty"`
}

type Config struct {
	Secret     []byte
	AccessTTL  time.Duration
	RefreshTTL time.Duration
}

func (c Config) accessTTL() time.Duration {
	if c.AccessTTL > 0 {
		return c.AccessTTL
	}
	return DefaultAccessTTL
}

func (c Config) refreshTTL() time.Duration {
	if c.RefreshTTL > 0 {
		return c.RefreshTTL
	}
	return DefaultRefreshTTL
}

func (c Config) AccessTTLSeconds() int64 {
	return int64(c.accessTTL().Seconds())
}

func (c Config) RefreshTTLDuration() time.Duration {
	return c.refreshTTL()
}

type IssueInput struct {
	UserID             uint
	Email              string
	Role               string
	VerificationStatus string
	Scope              string
}

func IssueTokenPair(cfg Config, in IssueInput) (accessToken, refreshToken string, err error) {
	now := time.Now()

	accessToken, err = sign(cfg.Secret, in, TokenTypeAccess, now, cfg.accessTTL())
	if err != nil {
		return "", "", fmt.Errorf("sign access token: %w", err)
	}

	refreshToken, err = sign(cfg.Secret, in, TokenTypeRefresh, now, cfg.refreshTTL())
	if err != nil {
		return "", "", fmt.Errorf("sign refresh token: %w", err)
	}

	return accessToken, refreshToken, nil
}

func IssueAccessToken(cfg Config, in IssueInput) (string, error) {
	return sign(cfg.Secret, in, TokenTypeAccess, time.Now(), cfg.accessTTL())
}

func sign(secret []byte, in IssueInput, tokenType string, now time.Time, ttl time.Duration) (string, error) {
	c := Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(ttl)),
		},
		UserID:             in.UserID,
		Email:              in.Email,
		Role:               in.Role,
		VerificationStatus: in.VerificationStatus,
		TokenType:          tokenType,
		Scope:              in.Scope,
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, c).SignedString(secret)
}

func Parse(secret []byte, raw string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(raw, &Claims{}, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return secret, nil
	})

	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return nil, ErrTokenExpired
		}
		return nil, ErrTokenInvalid
	}

	c, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, ErrTokenInvalid
	}

	return c, nil
}

func ParseString(secret, raw string) (*Claims, error) {
	return Parse([]byte(secret), raw)
}
