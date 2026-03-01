package notification

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

const (
	defaultLimit = 20
	maxLimit     = 50
)

type Repository interface {
	Create(ctx context.Context, n *Notification) error
	Get(ctx context.Context, role RecipientRole, recipientID, id uint) (*Notification, error)
	List(ctx context.Context, role RecipientRole, recipientID uint, q ListQuery) ([]Notification, *uint, error)
	Patch(ctx context.Context, role RecipientRole, recipientID, id uint, isRead bool) (*Notification, error)
	PatchBulk(ctx context.Context, role RecipientRole, recipientID uint, ids []uint, isRead bool) (int64, error)
}

type repo struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &repo{db: db} }

func (r *repo) Create(ctx context.Context, n *Notification) error {
	return r.db.WithContext(ctx).Create(n).Error
}

func (r *repo) Get(ctx context.Context, role RecipientRole, recipientID, id uint) (*Notification, error) {
	var n Notification
	err := r.db.WithContext(ctx).
		Where("id = ? AND recipient_role = ? AND recipient_id = ?", id, role, recipientID).
		First(&n).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrNotFound
	}
	return &n, err
}

func (r *repo) List(ctx context.Context, role RecipientRole, recipientID uint, q ListQuery) ([]Notification, *uint, error) {
	limit := q.Limit
	if limit <= 0 || limit > maxLimit {
		limit = defaultLimit
	}

	db := r.db.WithContext(ctx).
		Where("recipient_role = ? AND recipient_id = ?", role, recipientID).
		Order("id DESC").
		Limit(limit + 1)

	if q.UnreadOnly {
		db = db.Where("is_read = ?", false)
	}
	if q.Cursor > 0 {
		db = db.Where("id < ?", q.Cursor)
	}

	var rows []Notification
	if err := db.Find(&rows).Error; err != nil {
		return nil, nil, err
	}

	hasMore := len(rows) > limit
	if hasMore {
		rows = rows[:limit]
	}

	var nextCursor *uint
	if hasMore {
		last := rows[len(rows)-1].ID
		nextCursor = &last
	}

	return rows, nextCursor, nil
}

func (r *repo) Patch(ctx context.Context, role RecipientRole, recipientID, id uint, isRead bool) (*Notification, error) {
	updates := map[string]any{"is_read": isRead, "read_at": nil}
	if isRead {
		updates["read_at"] = gorm.Expr("NOW()")
	}

	if err := r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("id = ? AND recipient_role = ? AND recipient_id = ?", id, role, recipientID).
		Updates(updates).Error; err != nil {
		return nil, err
	}

	return r.Get(ctx, role, recipientID, id)
}

func (r *repo) PatchBulk(ctx context.Context, role RecipientRole, recipientID uint, ids []uint, isRead bool) (int64, error) {
	updates := map[string]any{"is_read": isRead, "read_at": nil}
	if isRead {
		updates["read_at"] = gorm.Expr("NOW()")
	}

	res := r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("recipient_role = ? AND recipient_id = ?", role, recipientID).
		Where("id IN ? AND is_read = ?", ids, !isRead).
		Updates(updates)

	return res.RowsAffected, res.Error
}
