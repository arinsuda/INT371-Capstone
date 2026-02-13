package chat

import (
	"changsure-core-service/pkg/storage"
	"context"
	"errors"
	"fmt"
	"time"

	"gorm.io/gorm"
)

var (
	ErrMessageNotFound = errors.New("message not found")

	ErrUnauthorizedAccess = errors.New("unauthorized access")
)

type Repository interface {
	Create(ctx context.Context, msg *ChatMessage) error
	GetByID(ctx context.Context, id uint) (*ChatMessage, error)
	GetHistory(ctx context.Context, bookingID uint, query GetHistoryQuery) ([]ChatMessage, error)
	MarkMessagesAsRead(ctx context.Context, messageIDs []uint) error
	GetUnreadCount(ctx context.Context, bookingID uint, userRole string, lastReadTime time.Time) (int64, error)

	GetChatRooms(ctx context.Context, userID uint, role string) ([]ChatRoomResponse, error)
}

type repository struct {
	db      *gorm.DB
	storage storage.Storage
}

func NewRepository(db *gorm.DB, storage storage.Storage) Repository {
	return &repository{
		db:      db,
		storage: storage,
	}
}

func (r *repository) Create(ctx context.Context, msg *ChatMessage) error {
	if msg == nil {
		return errors.New("message cannot be nil")
	}

	return r.db.WithContext(ctx).Create(msg).Error
}

func (r *repository) GetByID(ctx context.Context, id uint) (*ChatMessage, error) {
	var msg ChatMessage

	err := r.db.WithContext(ctx).
		Where("id = ?", id).
		First(&msg).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrMessageNotFound
		}
		return nil, err
	}

	return &msg, nil
}

func (r *repository) GetHistory(ctx context.Context, bookingID uint, query GetHistoryQuery) ([]ChatMessage, error) {
	var msgs []ChatMessage

	err := r.db.WithContext(ctx).
		Where("booking_id = ?", bookingID).
		Order("created_at DESC").
		Limit(query.Limit).
		Offset(query.Offset).
		Find(&msgs).Error

	if err != nil {
		return nil, fmt.Errorf("failed to get chat history: %w", err)
	}

	return msgs, nil
}

func (r *repository) MarkMessagesAsRead(ctx context.Context, messageIDs []uint) error {
	if len(messageIDs) == 0 {
		return nil
	}

	result := r.db.WithContext(ctx).
		Model(&ChatMessage{}).
		Where("id IN ?", messageIDs).
		Update("is_read", true)

	if result.Error != nil {
		return fmt.Errorf("failed to mark messages as read: %w", result.Error)
	}

	return nil
}

func (r *repository) GetUnreadCount(ctx context.Context, bookingID uint, userRole string, lastReadTime time.Time) (int64, error) {
	var count int64

	err := r.db.WithContext(ctx).
		Model(&ChatMessage{}).
		Where("booking_id = ?", bookingID).
		Where("created_at > ?", lastReadTime).
		Where("sender_role != ?", userRole).
		Count(&count).Error

	if err != nil {
		return 0, fmt.Errorf("failed to get unread count: %w", err)
	}

	return count, nil
}

func (r *repository) GetChatRooms(ctx context.Context, userID uint, role string) ([]ChatRoomResponse, error) {
	var results []ChatRoomResponse

	targetTable, targetIDCol, myIDCol, nameCol, imgCol := r.getRoomQueryParams(role)

	query := r.buildChatRoomsQuery(targetTable, targetIDCol, myIDCol, nameCol, imgCol)

	err := r.db.WithContext(ctx).
		Raw(query, role, role, userID).
		Scan(&results).Error

	if err != nil {
		return nil, fmt.Errorf("failed to get chat rooms: %w", err)
	}

	for i := range results {
		if results[i].OtherPersonImg != "" {
			url, err := r.storage.PresignGet(ctx, results[i].OtherPersonImg, 24*time.Hour, false)
			if err == nil {
				results[i].OtherPersonImg = url
			}
		}

		if results[i].LastMsgType == MsgTypeImage && results[i].LastMessage != "" {
			if url, err := r.storage.PresignGet(ctx, results[i].LastMessage, 24*time.Hour, false); err == nil {
				results[i].LastMessage = url
			}
		}
	}

	return results, nil
}

func (r *repository) getRoomQueryParams(role string) (targetTable, targetIDCol, myIDCol, nameCol, imgCol string) {
	if role == "technician" {
		return "customers", "customer_id", "technician_id", "first_name", "avatar_url"
	}
	return "technicians", "technician_id", "customer_id", "first_name", "avatar_url"
}

func (r *repository) buildChatRoomsQuery(targetTable, targetIDCol, myIDCol, nameCol, imgCol string) string {
	return fmt.Sprintf(`
		SELECT 
			b.id as booking_id,
			b.booking_number,
			b.status as booking_status,
			u.id as other_person_id,
			u.%s as other_person_name,
			u.%s as other_person_img,
			COALESCE(m.content, '') as last_message,
			COALESCE(m.type, 'TEXT') as last_msg_type,
			COALESCE(m.created_at, b.created_at) as last_msg_time,
			(
				SELECT COUNT(*) 
				FROM chat_messages cm 
				WHERE cm.booking_id = b.id 
				  AND cm.created_at > CASE
						WHEN ? = 'customer' THEN COALESCE(b.last_read_by_customer, '1970-01-01')
						ELSE COALESCE(b.last_read_by_technician, '1970-01-01')
					END
				  AND cm.sender_role != ?
			) as unread_count
		FROM bookings b
		LEFT JOIN %s u ON u.id = b.%s
		LEFT JOIN LATERAL (
			SELECT *
			FROM chat_messages
			WHERE booking_id = b.id
			ORDER BY created_at DESC
			LIMIT 1
		) m ON TRUE
		WHERE b.%s = ?
		  AND b.status NOT IN ('PENDING')
		ORDER BY last_msg_time DESC
	`, nameCol, imgCol, targetTable, targetIDCol, myIDCol)
}
