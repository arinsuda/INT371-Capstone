package chat

import (
	"changsure-core-service/pkg/storage"
	"context"
	"errors"
	"fmt"
	"strings"
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
	GetUserInfo(ctx context.Context, userID uint, userRole string) (name, avatar string, err error)
	GetChatRooms(ctx context.Context, userID uint, role string, statusFilter string, searchQuery string) ([]ChatRoomResponse, error)
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
	var rows []chatMessageRow

	err := r.db.WithContext(ctx).
		Table("chat_messages cm").
		Select(`
			cm.id,
			cm.booking_id,
			b.booking_number,
			sc.cat_name as service_category,
			cm.sender_id,
			cm.sender_role,
			cm.type,
			cm.content,
			cm.is_read,
			cm.created_at,
			CASE 
				WHEN cm.sender_role = 'customer' THEN 
					(SELECT CONCAT(first_name, ' ', last_name) FROM customers WHERE id = cm.sender_id)
				WHEN cm.sender_role = 'technician' THEN 
					(SELECT CONCAT(first_name, ' ', last_name) FROM technicians WHERE id = cm.sender_id)
			END as sender_name,
			CASE 
				WHEN cm.sender_role = 'customer' THEN 
					(SELECT avatar_url FROM customers WHERE id = cm.sender_id)
				WHEN cm.sender_role = 'technician' THEN 
					(SELECT avatar_url FROM technicians WHERE id = cm.sender_id)
			END as sender_avatar
		`).
		Joins("LEFT JOIN bookings b ON b.id = cm.booking_id").
		Joins("LEFT JOIN technician_services ts ON ts.id = b.technician_service_id").
		Joins("LEFT JOIN services s ON s.id = ts.service_id").
		Joins("LEFT JOIN service_categories sc ON sc.id = s.category_id").
		Where("cm.booking_id = ?", bookingID).
		Order("cm.created_at DESC").
		Limit(query.Limit).
		Offset(query.Offset).
		Scan(&rows).Error

	if err != nil {
		return nil, fmt.Errorf("failed to get chat history: %w", err)
	}

	msgs := make([]ChatMessage, len(rows))
	for i, row := range rows {
		msgs[i] = ChatMessage{
			ID:              row.ID,
			BookingID:       row.BookingID,
			BookingNumber:   row.BookingNumber,
			ServiceCategory: row.ServiceCategory,
			SenderID:        row.SenderID,
			SenderRole:      row.SenderRole,
			SenderName:      row.SenderName,
			SenderAvatar:    row.SenderAvatar,
			Type:            row.Type,
			Content:         row.Content,
			IsRead:          row.IsRead,
			CreatedAt:       row.CreatedAt,
		}
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
		Where("is_read = ?", false).
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
		Where("is_read = ?", false).
		Count(&count).Error

	if err != nil {
		return 0, fmt.Errorf("failed to get unread count: %w", err)
	}

	return count, nil
}

func (r *repository) GetUserInfo(ctx context.Context, userID uint, userRole string) (name, avatar string, err error) {
	var result struct {
		FirstName string
		LastName  string
		AvatarURL string
	}

	var tableName string
	if userRole == "customer" {
		tableName = "customers"
	} else if userRole == "technician" {
		tableName = "technicians"
	} else {
		return "", "", errors.New("invalid role")
	}

	err = r.db.WithContext(ctx).
		Table(tableName).
		Select("first_name, last_name, avatar_url").
		Where("id = ?", userID).
		Scan(&result).Error

	if err != nil {
		return "", "", fmt.Errorf("failed to get user info: %w", err)
	}

	fullName := result.FirstName + " " + result.LastName
	return fullName, result.AvatarURL, nil
}

func (r *repository) GetChatRooms(ctx context.Context, userID uint, role string, statusFilter string, searchQuery string) ([]ChatRoomResponse, error) {
	var results []ChatRoomResponse

	targetTable, targetIDCol, myIDCol, nameCol, imgCol := r.getRoomQueryParams(role)

	query := r.buildChatRoomsQuery(targetTable, targetIDCol, myIDCol, nameCol, imgCol, statusFilter, searchQuery)

	err := r.db.WithContext(ctx).
		Raw(query, role, role, role, userID).
		Scan(&results).Error

	if err != nil {
		return nil, fmt.Errorf("failed to get chat rooms: %w", err)
	}

	for i := range results {
		if results[i].OtherPersonImg != "" && !strings.HasPrefix(results[i].OtherPersonImg, "http") {
			url, err := r.storage.PresignGet(ctx, results[i].OtherPersonImg, 24*time.Hour, false)
			if err == nil {
				results[i].OtherPersonImg = url
			}
		}

		if results[i].LastMsgType == MsgTypeImage && results[i].LastMessage != "" && !strings.HasPrefix(results[i].LastMessage, "http") {
			if url, err := r.storage.PresignGet(ctx, results[i].LastMessage, 24*time.Hour, false); err == nil {
				results[i].LastMessage = url
			}
		}
	}

	return results, nil
}

func (r *repository) getRoomQueryParams(role string) (targetTable, targetIDCol, myIDCol, nameExpr, imgCol string) {
	if role == "technician" {
		return "customers", "customer_id", "technician_id",
			"CONCAT(u.first_name, ' ', u.last_name)",
			"avatar_url"
	}
	return "technicians", "technician_id", "customer_id",
		"CONCAT(u.first_name, ' ', u.last_name)",
		"avatar_url"
}

func (r *repository) buildChatRoomsQuery(targetTable, targetIDCol, myIDCol, nameExpr, imgCol, statusFilter, searchQuery string) string {
	whereClause := fmt.Sprintf("WHERE b.%s = ?", myIDCol)

	if statusFilter != "" {
		statuses := strings.Split(statusFilter, ",")
		if len(statuses) == 1 {
			whereClause += fmt.Sprintf(" AND b.status = '%s'", strings.TrimSpace(statuses[0]))
		} else {
			statusList := make([]string, 0, len(statuses))
			for _, s := range statuses {
				trimmed := strings.TrimSpace(s)
				if trimmed != "" {
					statusList = append(statusList, fmt.Sprintf("'%s'", trimmed))
				}
			}
			if len(statusList) > 0 {
				whereClause += fmt.Sprintf(" AND b.status IN (%s)", strings.Join(statusList, ","))
			}
		}
	} else {
		whereClause += ` AND b.status IN (
            'ACCEPTED', 
            'IN_PROGRESS', 
            'WAITING_PAYMENT',
            'COMPLETED',
            'CANCELLED'
        )`
	}

	if searchQuery != "" {
		escapedQuery := strings.ReplaceAll(searchQuery, "'", "''")
		whereClause += fmt.Sprintf(` AND (
			b.booking_number LIKE '%%%s%%' OR
			%s LIKE '%%%s%%' OR
			sc.cat_name LIKE '%%%s%%' OR
			m.content LIKE '%%%s%%'
		)`, escapedQuery, nameExpr, escapedQuery, escapedQuery, escapedQuery)
	}

	return fmt.Sprintf(`
		SELECT 
			b.id as booking_id,
			b.booking_number,
			b.status as booking_status,
			sc.cat_name as service_category,
			u.id as other_person_id,
			%s as other_person_name,
			u.%s as other_person_img,
			COALESCE(m.content, '') as last_message,
			COALESCE(m.type, 'TEXT') as last_msg_type,
			COALESCE(m.created_at, b.created_at) as last_msg_time,
			CASE 
				WHEN m.sender_role = ? THEN 'me'
				WHEN m.sender_role IS NOT NULL THEN 'other'
				ELSE ''
			END as last_sender,
			(
				SELECT COUNT(*) 
				FROM chat_messages cm 
				WHERE cm.booking_id = b.id 
				  AND cm.created_at > CASE
						WHEN ? = 'customer' THEN COALESCE(b.last_read_by_customer, '1970-01-01')
						ELSE COALESCE(b.last_read_by_technician, '1970-01-01')
					END
				  AND cm.sender_role != ?
				  AND cm.is_read = false
			) as unread_count
		FROM bookings b
		LEFT JOIN %s u ON u.id = b.%s
		LEFT JOIN technician_services ts ON ts.id = b.technician_service_id
		LEFT JOIN services s ON s.id = ts.service_id
		LEFT JOIN service_categories sc ON sc.id = s.category_id
		LEFT JOIN LATERAL (
			SELECT content, type, created_at, sender_role
			FROM chat_messages
			WHERE booking_id = b.id
			ORDER BY created_at DESC
			LIMIT 1
		) m ON TRUE
		%s
		ORDER BY last_msg_time DESC
	`, nameExpr, imgCol, targetTable, targetIDCol, whereClause)
}
