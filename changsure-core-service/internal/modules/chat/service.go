package chat

import (
	apperrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/internal/realtime"
	"changsure-core-service/pkg/storage"
	"context"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
)

const (
	MaxImageSize = 10 * 1024 * 1024

	MaxMessageLength = 5000
)

var (
	AllowedImageTypes = map[string]bool{
		"image/jpeg": true,
		"image/jpg":  true,
		"image/png":  true,
		"image/webp": true,
	}

	ErrInvalidImageType = errors.New("invalid image type")

	ErrImageTooLarge = errors.New("image too large")

	ErrMessageTooLong = errors.New("message too long")
)

type Service interface {
	SendMessage(ctx context.Context, userID uint, userRole string, req SendMessageReq, file *multipart.FileHeader) (*ChatMessageResponse, error)
	GetChatHistory(ctx context.Context, userID uint, bookingID uint, query GetHistoryQuery) ([]ChatMessageResponse, error)
	GetChatRooms(ctx context.Context, userID uint, userRole string, statusFilter string, searchQuery string) ([]ChatRoomResponse, error)
	MarkRoomAsRead(ctx context.Context, userID uint, userRole string, bookingID uint) error
	MarkMessagesAsRead(
		ctx context.Context,
		userID uint,
		userRole string,
		bookingID uint,
		messageIDs []uint,
	) error
}

type service struct {
	chatRepo    Repository
	bookingRepo booking.Repository
	hub         *realtime.Hub
	storage     storage.Storage
}

func NewService(
	chatRepo Repository,
	bookingRepo booking.Repository,
	hub *realtime.Hub,
	storage storage.Storage,
) Service {
	return &service{
		chatRepo:    chatRepo,
		bookingRepo: bookingRepo,
		hub:         hub,
		storage:     storage,
	}
}

func (s *service) SendMessage(
	ctx context.Context,
	userID uint,
	userRole string,
	req SendMessageReq,
	file *multipart.FileHeader,
) (*ChatMessageResponse, error) {

	if err := req.Validate(); err != nil {
		return nil, apperrors.NewBadRequest(err.Error())
	}

	bk, receiverID, err := s.verifyBookingAccess(ctx, userID, userRole, req.BookingID)
	if err != nil {
		return nil, err
	}

	if !s.canChat(bk.Status) {
		var msg string
		switch bk.Status {
		case booking.BookingStatusPending:
			msg = "รอช่างยอมรับงานก่อนจึงจะแชทได้"
		case booking.BookingStatusRejected:
			msg = "ช่างปฏิเสธงานนี้แล้ว ไม่สามารถส่งข้อความได้"
		case booking.BookingStatusCompleted:
			msg = "งานเสร็จสิ้นแล้ว ไม่สามารถส่งข้อความได้"
		case booking.BookingStatusCancelled:
			msg = "งานถูกยกเลิกแล้ว ไม่สามารถส่งข้อความได้"
		default:
			msg = fmt.Sprintf("ไม่สามารถส่งข้อความได้ในสถานะ: %s", bk.Status)
		}
		return nil, apperrors.NewUnprocessable(msg)
	}

	content, err := s.processMessageContent(ctx, req, file, bk.ID)
	if err != nil {
		return nil, err
	}

	senderName, senderAvatar, err := s.getSenderInfo(ctx, userID, userRole)
	if err != nil {
		return nil, err
	}

	msg := &ChatMessage{
		BookingID:       req.BookingID,
		BookingNumber:   bk.BookingNumber,
		ServiceCategory: bk.TechnicianService.Service.Category.CatName,
		SenderID:        userID,
		SenderRole:      userRole,
		SenderName:      senderName,
		SenderAvatar:    senderAvatar,
		Type:            req.Type,
		Content:         content,
		CreatedAt:       time.Now(),
	}

	if err := s.chatRepo.Create(ctx, msg); err != nil {
		return nil, apperrors.NewInternal(err)
	}

	response := s.prepareMessageResponse(ctx, msg)

	s.broadcastNewMessage(msg, userID, userRole, receiverID)

	return response, nil
}

func (s *service) GetChatHistory(
	ctx context.Context,
	userID uint,
	bookingID uint,
	query GetHistoryQuery,
) ([]ChatMessageResponse, error) {

	query.SetDefaults()

	if err := query.Validate(); err != nil {
		return nil, apperrors.NewBadRequest(err.Error())
	}

	bk, err := s.bookingRepo.FindByID(ctx, bookingID)
	if err != nil {
		return nil, apperrors.NewNotFound("ไม่พบข้อมูลการจอง")
	}

	userRole, err := s.getUserRole(bk, userID)
	if err != nil {
		return nil, apperrors.NewForbidden("คุณไม่มีสิทธิ์เข้าถึงห้องแชทนี้")
	}

	if !s.canViewChat(bk.Status) {
		return nil, apperrors.NewForbidden("ไม่สามารถเข้าถึงแชทได้ในสถานะนี้")
	}

	msgs, err := s.chatRepo.GetHistory(ctx, bookingID, query)
	if err != nil {
		return nil, apperrors.NewInternal(err)
	}

	responses := make([]ChatMessageResponse, len(msgs))
	for i, msg := range msgs {
		responses[i] = *s.prepareMessageResponse(ctx, &msg)
	}

	if s.canViewChat(bk.Status) {
		go s.updateRoomReadState(context.Background(), bk, userID, userRole)
	}

	return responses, nil
}

func (s *service) GetChatRooms(
	ctx context.Context,
	userID uint,
	userRole string,
	statusFilter string,
	searchQuery string,
) ([]ChatRoomResponse, error) {
	rooms, err := s.chatRepo.GetChatRooms(ctx, userID, userRole, statusFilter, searchQuery)
	if err != nil {
		return nil, apperrors.NewInternal(err)
	}

	if rooms == nil {
		return []ChatRoomResponse{}, nil
	}

	for i := range rooms {
		rooms[i].CanSendMessage = s.canChat(rooms[i].BookingStatus)
	}

	return rooms, nil
}

func (s *service) MarkRoomAsRead(
	ctx context.Context,
	userID uint,
	userRole string,
	bookingID uint,
) error {

	bk, err := s.bookingRepo.FindByID(ctx, bookingID)
	if err != nil {
		return apperrors.NewNotFound("ไม่พบข้อมูลการจอง")
	}

	if _, err := s.getUserRole(bk, userID); err != nil {
		return apperrors.NewForbidden("คุณไม่มีสิทธิ์เข้าถึงห้องแชทนี้")
	}

	if err := s.updateRoomReadState(ctx, bk, userID, userRole); err != nil {
		return apperrors.NewInternal(err)
	}

	return nil
}

func (s *service) MarkMessagesAsRead(
	ctx context.Context,
	userID uint,
	userRole string,
	bookingID uint,
	messageIDs []uint,
) error {
	bk, _, err := s.verifyBookingAccess(ctx, userID, userRole, bookingID)
	if err != nil {
		return err
	}

	if err := s.chatRepo.MarkMessagesAsRead(ctx, messageIDs); err != nil {
		return err
	}

	payload := realtime.MarshalEvent(realtime.EventChatMessageRead, map[string]any{
		"booking_id":  bookingID,
		"message_ids": messageIDs,
		"reader_role": userRole,
		"read_at":     time.Now(),
	})

	if userRole == "technician" {
		s.hub.BroadcastToCustomer(bk.CustomerID, payload)
	} else {
		s.hub.BroadcastToTechnician(bk.TechnicianID, payload)
	}

	return nil
}

func (s *service) verifyBookingAccess(
	ctx context.Context,
	userID uint,
	userRole string,
	bookingID uint,
) (*booking.Booking, uint, error) {
	bk, err := s.bookingRepo.FindByID(ctx, bookingID)
	if err != nil {
		return nil, 0, apperrors.NewNotFound("ไม่พบข้อมูลการจอง")
	}

	var receiverID uint

	switch userRole {
	case "technician":
		if bk.TechnicianID != userID {
			return nil, 0, apperrors.NewForbidden("คุณไม่ใช่ช่างผู้รับผิดชอบงานนี้")
		}
		receiverID = bk.CustomerID

	case "customer":
		if bk.CustomerID != userID {
			return nil, 0, apperrors.NewForbidden("คุณไม่ใช่ลูกค้าเจ้าของงานนี้")
		}
		receiverID = bk.TechnicianID

	default:
		return nil, 0, apperrors.NewBadRequest("Invalid role")
	}

	return bk, receiverID, nil
}

func (s *service) getUserRole(bk *booking.Booking, userID uint) (string, error) {
	if bk.TechnicianID == userID {
		return "technician", nil
	}
	if bk.CustomerID == userID {
		return "customer", nil
	}
	return "", errors.New("unauthorized")
}

func (s *service) getSenderInfo(ctx context.Context, userID uint, userRole string) (name, avatar string, err error) {
	return s.chatRepo.GetUserInfo(ctx, userID, userRole)
}

func (s *service) processMessageContent(
	ctx context.Context,
	req SendMessageReq,
	file *multipart.FileHeader,
	bookingID uint,
) (string, error) {
	switch req.Type {
	case MsgTypeText:
		return s.processTextContent(req.Content)

	case MsgTypeImage:
		return s.processImageContent(ctx, file, bookingID)

	default:
		return "", apperrors.NewBadRequest("Invalid message type")
	}
}

func (s *service) processTextContent(content string) (string, error) {
	trimmed := strings.TrimSpace(content)

	if trimmed == "" {
		return "", apperrors.NewBadRequest("Content is required for TEXT message")
	}

	if len(trimmed) > MaxMessageLength {
		return "", apperrors.NewBadRequest(
			fmt.Sprintf("Message too long (max %d characters)", MaxMessageLength),
		)
	}

	return trimmed, nil
}

func (s *service) processImageContent(
	ctx context.Context,
	file *multipart.FileHeader,
	bookingID uint,
) (string, error) {
	if file == nil {
		return "", apperrors.NewBadRequest("Image file is required for IMAGE message")
	}

	if file.Size > MaxImageSize {
		return "", apperrors.NewBadRequest(
			fmt.Sprintf("Image too large (max %dMB)", MaxImageSize/(1024*1024)),
		)
	}

	contentType := file.Header.Get("Content-Type")
	if !AllowedImageTypes[contentType] {
		return "", apperrors.NewBadRequest(
			"Invalid image type. Allowed: JPEG, PNG, WebP",
		)
	}

	src, err := file.Open()
	if err != nil {
		return "", apperrors.NewInternal(fmt.Errorf("failed to open file: %w", err))
	}
	defer src.Close()

	ext := filepath.Ext(file.Filename)
	newFilename := fmt.Sprintf("%s%s", uuid.New().String(), ext)
	folder := fmt.Sprintf("chats/%d", bookingID)

	key, err := s.storage.UploadFile(ctx, src.(io.Reader), newFilename, folder, file.Size, contentType)
	if err != nil {
		return "", apperrors.NewInternal(fmt.Errorf("failed to upload image: %w", err))
	}

	return key, nil
}

func (s *service) prepareMessageResponse(ctx context.Context, msg *ChatMessage) *ChatMessageResponse {
	response := &ChatMessageResponse{}
	response.FromModel(msg)

	if msg.Type == MsgTypeImage {
		if url, err := s.storage.PresignGet(ctx, msg.Content, 24*time.Hour, false); err == nil {
			response.Content = url
		}
	}

	if msg.SenderAvatar != "" {
		if url, err := s.storage.PresignGet(ctx, msg.SenderAvatar, 24*time.Hour, false); err == nil {
			response.Sender.SenderAvatar = url
		}
	}

	return response
}

func (s *service) broadcastNewMessage(msg *ChatMessage, senderID uint, senderRole string, receiverID uint) {
	content := msg.Content
	if msg.Type == MsgTypeImage && msg.Content != "" {
		if url, err := s.storage.PresignGet(context.Background(), msg.Content, 24*time.Hour, false); err == nil {
			content = url
		}
	}

	senderAvatar := msg.SenderAvatar
	if senderAvatar != "" && !strings.HasPrefix(senderAvatar, "http") {
		if url, err := s.storage.PresignGet(context.Background(), senderAvatar, 24*time.Hour, false); err == nil {
			senderAvatar = url
		}
	}

	newMsgPayload := realtime.MarshalEvent(realtime.EventChatMessageNew, map[string]any{
		"id":         msg.ID,
		"booking_id": msg.BookingID,
		"booking": map[string]any{
			"booking_number":   msg.BookingNumber,
			"service_category": msg.ServiceCategory,
		},
		"sender": map[string]any{
			"sender_id":     msg.SenderID,
			"sender_role":   msg.SenderRole,
			"sender_name":   msg.SenderName,
			"sender_avatar": senderAvatar,
		},
		"type":       msg.Type,
		"content":    content,
		"is_read":    msg.IsRead,
		"created_at": msg.CreatedAt,
	})

	if senderRole == "technician" {
		s.hub.BroadcastToTechnician(senderID, newMsgPayload)
		s.hub.BroadcastToCustomer(receiverID, newMsgPayload)
	} else {
		s.hub.BroadcastToCustomer(senderID, newMsgPayload)
		s.hub.BroadcastToTechnician(receiverID, newMsgPayload)
	}

	chatListPayloadSender := realtime.MarshalEvent(realtime.EventChatListUpdated, map[string]any{
		"booking_id":    msg.BookingID,
		"last_message":  content,
		"last_msg_type": msg.Type,
		"last_msg_time": msg.CreatedAt,
		"last_sender":   "me",
	})

	chatListPayloadReceiver := realtime.MarshalEvent(realtime.EventChatListUpdated, map[string]any{
		"booking_id":    msg.BookingID,
		"last_message":  content,
		"last_msg_type": msg.Type,
		"last_msg_time": msg.CreatedAt,
		"last_sender":   "other",
	})

	if senderRole == "technician" {
		s.hub.BroadcastToTechnician(senderID, chatListPayloadSender)
		s.hub.BroadcastToCustomer(receiverID, chatListPayloadReceiver)
	} else {
		s.hub.BroadcastToCustomer(senderID, chatListPayloadSender)
		s.hub.BroadcastToTechnician(receiverID, chatListPayloadReceiver)
	}
}

func (s *service) updateRoomReadState(
	ctx context.Context,
	bk *booking.Booking,
	userID uint,
	role string,
) error {
	now := time.Now()

	err := s.bookingRepo.UpdateLastRead(ctx, bk.ID, role, now)
	if err != nil {
		return err
	}

	payload := realtime.MarshalEvent(realtime.EventChatRoomRead, map[string]any{
		"booking_id":  bk.ID,
		"reader_role": role,
		"read_at":     now,
	})

	if role == "technician" {
		s.hub.BroadcastToCustomer(bk.CustomerID, payload)
	} else {
		s.hub.BroadcastToTechnician(bk.TechnicianID, payload)
	}

	return nil
}

func (s *service) canViewChat(status string) bool {
	switch status {
	case booking.BookingStatusAccepted,
		booking.BookingStatusInProgress,
		booking.BookingStatusWaitingPayment,
		booking.BookingStatusCompleted,
		booking.BookingStatusCancelled:
		return true
	default:
		return false
	}
}

func (s *service) canChat(status string) bool {
	switch status {
	case booking.BookingStatusAccepted,
		booking.BookingStatusInProgress,
		booking.BookingStatusWaitingPayment:
		return true
	default:
		return false
	}
}
