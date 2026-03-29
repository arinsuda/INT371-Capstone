package auth

import (
	"context"
	"time"

	"gorm.io/gorm"
)

type TokenRepository interface {
	Save(ctx context.Context, t *RefreshToken) error
	FindByToken(ctx context.Context, token string) (*RefreshToken, error)
	Revoke(ctx context.Context, token string) error
	RevokeAllByUser(ctx context.Context, userID uint, role string) error
	DeleteExpired(ctx context.Context) error
}

type tokenRepository struct{ db *gorm.DB }

func NewTokenRepository(db *gorm.DB) TokenRepository {
	return &tokenRepository{db: db}
}

func (r *tokenRepository) Save(ctx context.Context, t *RefreshToken) error {
	return r.db.WithContext(ctx).Create(t).Error
}

func (r *tokenRepository) FindByToken(ctx context.Context, token string) (*RefreshToken, error) {
	var t RefreshToken
	err := r.db.WithContext(ctx).
		Where("token = ? AND revoked_at IS NULL AND expires_at > ?", token, time.Now()).
		First(&t).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, ErrRefreshTokenNotFound
		}
		return nil, err
	}
	return &t, nil
}

func (r *tokenRepository) Revoke(ctx context.Context, token string) error {
	now := time.Now()
	result := r.db.WithContext(ctx).Model(&RefreshToken{}).
		Where("token = ? AND revoked_at IS NULL", token).
		Update("revoked_at", now)
	if result.Error != nil {
		return result.Error
	}

	return nil
}

func (r *tokenRepository) RevokeAllByUser(ctx context.Context, userID uint, role string) error {
	now := time.Now()
	return r.db.WithContext(ctx).Model(&RefreshToken{}).
		Where("user_id = ? AND role = ? AND revoked_at IS NULL", userID, role).
		Update("revoked_at", now).Error
}

func (r *tokenRepository) DeleteExpired(ctx context.Context) error {
	return r.db.WithContext(ctx).
		Where("expires_at < ?", time.Now()).
		Delete(&RefreshToken{}).Error
}
