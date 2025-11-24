package auth

import (
	"context"
	"time"

	"gorm.io/gorm"
)

type RefreshTokenRepository interface {
	Create(ctx context.Context, rt *RefreshToken) error
	FindActiveByHash(ctx context.Context, hash string) (*RefreshToken, error)
	RevokeAndReplace(ctx context.Context, oldToken *RefreshToken, newToken *RefreshToken) error
}

type refreshTokenRepo struct {
	db *gorm.DB
}

func NewRefreshTokenRepository(db *gorm.DB) RefreshTokenRepository {
	return &refreshTokenRepo{db: db}
}

func (r *refreshTokenRepo) Create(ctx context.Context, rt *RefreshToken) error {
	return r.db.WithContext(ctx).Create(rt).Error
}

func (r *refreshTokenRepo) FindActiveByHash(ctx context.Context, hash string) (*RefreshToken, error) {
	var rt RefreshToken
	err := r.db.WithContext(ctx).
		Where("token_hash = ? AND revoked_at IS NULL AND expires_at > ?", hash, time.Now()).
		First(&rt).Error
	if err != nil {
		return nil, err
	}
	return &rt, nil
}

func (r *refreshTokenRepo) RevokeAndReplace(ctx context.Context, oldToken *RefreshToken, newToken *RefreshToken) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		now := time.Now()
		if err := tx.Model(oldToken).Update("revoked_at", &now).Error; err != nil {
			return err
		}
		return tx.Create(newToken).Error
	})
}
