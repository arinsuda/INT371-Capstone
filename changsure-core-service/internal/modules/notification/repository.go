package notification

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, n *Notification) error
	List(ctx context.Context, role RecipientRole, recipientID uint, q ListQuery) ([]Notification, uint, error)
	UnreadCount(ctx context.Context, role RecipientRole, recipientID uint) (int64, error)
	MarkRead(ctx context.Context, role RecipientRole, recipientID uint, ids []uint) (int64, error)
	ReadAll(ctx context.Context, role RecipientRole, recipientID uint) (int64, error)
}

type repo struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repo{db: db}
}

func (r *repo) Create(ctx context.Context, n *Notification) error {
	return r.db.WithContext(ctx).Create(n).Error
}

func (r *repo) List(ctx context.Context, role RecipientRole, recipientID uint, q ListQuery) ([]Notification, uint, error) {
	limit := q.Limit
	if limit <= 0 || limit > 50 {
		limit = 20
	}

	db := r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("recipient_role = ? AND recipient_id = ?", role, recipientID).
		Order("id DESC").
		Limit(limit)

	if q.UnreadOnly {
		db = db.Where("is_read = ?", false)
	}
	if q.Cursor > 0 {

		db = db.Where("id < ?", q.Cursor)
	}

	var rows []Notification
	if err := db.Find(&rows).Error; err != nil {
		return nil, 0, err
	}

	var nextCursor uint
	if len(rows) > 0 {
		nextCursor = rows[len(rows)-1].ID
	}

	return rows, nextCursor, nil
}

func (r *repo) UnreadCount(ctx context.Context, role RecipientRole, recipientID uint) (int64, error) {
	var c int64
	err := r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("recipient_role = ? AND recipient_id = ? AND is_read = ?", role, recipientID, false).
		Count(&c).Error
	return c, err
}

func (r *repo) MarkRead(ctx context.Context, role RecipientRole, recipientID uint, ids []uint) (int64, error) {
	res := r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("recipient_role = ? AND recipient_id = ?", role, recipientID).
		Where("id IN ?", ids).
		Where("is_read = ?", false).
		Updates(map[string]any{
			"is_read": true,
			"read_at": gorm.Expr("NOW()"),
		})
	return res.RowsAffected, res.Error
}

func (r *repo) ReadAll(ctx context.Context, role RecipientRole, recipientID uint) (int64, error) {
	res := r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("recipient_role = ? AND recipient_id = ?", role, recipientID).
		Where("is_read = ?", false).
		Updates(map[string]any{
			"is_read": true,
			"read_at": gorm.Expr("NOW()"),
		})
	return res.RowsAffected, res.Error
}
