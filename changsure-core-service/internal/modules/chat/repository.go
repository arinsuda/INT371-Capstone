package chat

import (
	"changsure-core-service/pkg/storage"
	"context"
	"time"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, msg *ChatMessage) error
	GetHistory(ctx context.Context, bookingID uint, offset int, limit int) ([]ChatMessage, error)
	MarkAsRead(ctx context.Context, bookingID uint, readerID uint, readerRole string) error

	GetChatRooms(ctx context.Context, userID uint, role string) ([]ChatRoomResponse, error)
}

type repository struct {
	db      *gorm.DB
	storage storage.Storage
}

func NewRepository(db *gorm.DB, storage storage.Storage) Repository {
	return &repository{db: db, storage: storage}
}

func (r *repository) Create(ctx context.Context, msg *ChatMessage) error {
	return r.db.WithContext(ctx).Create(msg).Error
}

func (r *repository) GetHistory(ctx context.Context, bookingID uint, offset int, limit int) ([]ChatMessage, error) {
	var msgs []ChatMessage
	err := r.db.WithContext(ctx).
		Where("booking_id = ?", bookingID).
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&msgs).Error
	return msgs, err
}

func (r *repository) MarkAsRead(ctx context.Context, bookingID uint, readerID uint, readerRole string) error {

	senderRoleToUpdate := "technician"
	if readerRole == "technician" {
		senderRoleToUpdate = "customer"
	}

	return r.db.WithContext(ctx).
		Model(&ChatMessage{}).
		Where("booking_id = ? AND sender_role = ? AND is_read = ?", bookingID, senderRoleToUpdate, false).
		Update("is_read", true).Error
}

func (r *repository) GetChatRooms(ctx context.Context, userID uint, role string) ([]ChatRoomResponse, error) {
	var results []ChatRoomResponse

	var targetTable string
	var targetIDCol string
	var myIDCol string
	var nameCol string
	var imgCol string

	if role == "technician" {
		targetTable = "customers"
		targetIDCol = "customer_id"
		myIDCol = "technician_id"
		nameCol = "first_name"

		imgCol = "avatar_url"
	} else {
		targetTable = "technicians"
		targetIDCol = "technician_id"
		myIDCol = "customer_id"
		nameCol = "first_name"

		imgCol = "avatar_url"
	}

	query := `
		SELECT 
			b.id as booking_id,
			b.booking_number,
			b.status as booking_status,
			u.id as other_person_id,
			u.` + nameCol + ` as other_person_name,
			u.` + imgCol + ` as other_person_img,
			COALESCE(m.content, '') as last_message,
			COALESCE(m.type, 'TEXT') as last_msg_type,
			COALESCE(m.created_at, b.created_at) as last_msg_time,
			(
				SELECT COUNT(*) 
				FROM chat_messages cm 
				WHERE cm.booking_id = b.id 
				  AND cm.is_read = false 
				  AND cm.sender_role != ? -- นับเฉพาะที่คนอื่นส่งมา
			) as unread_count
		FROM bookings b
		LEFT JOIN ` + targetTable + ` u ON u.id = b.` + targetIDCol + `
		LEFT JOIN (
			SELECT t1.*
			FROM chat_messages t1
			JOIN (
				SELECT booking_id, MAX(created_at) as max_date
				FROM chat_messages
				GROUP BY booking_id
			) t2 ON t1.booking_id = t2.booking_id AND t1.created_at = t2.max_date
		) m ON m.booking_id = b.id
		WHERE b.` + myIDCol + ` = ?
		  AND b.status NOT IN ('PENDING') -- ไม่โชว์งานที่ยังไม่ได้รับ
		ORDER BY last_msg_time DESC
	`

	err := r.db.WithContext(ctx).Raw(query, role, userID).Scan(&results).Error

	for i := range results {
		if results[i].OtherPersonImg != "" {
			url, err := r.storage.PresignGet(ctx, results[i].OtherPersonImg, 24*time.Hour, false)
			if err == nil {
				results[i].OtherPersonImg = url
			}
		}
	}

	return results, err
}
