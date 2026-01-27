package chat

import (
	apperrors "changsure-core-service/internal/errors"
	"context"
	"errors"
	"time"

	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/internal/realtime"
)

type Service interface {
	SendMessage(ctx context.Context, userID uint, userRole string, req SendMessageReq) (*ChatMessage, error)
	GetChatHistory(ctx context.Context, userID uint, bookingID uint) ([]ChatMessage, error)

	GetChatRooms(ctx context.Context, userID uint, userRole string) ([]ChatRoomResponse, error)
}

type service struct {
	chatRepo    Repository
	bookingRepo booking.Repository
	hub         *realtime.Hub
}

func NewService(chatRepo Repository, bookingRepo booking.Repository, hub *realtime.Hub) Service {
	return &service{
		chatRepo:    chatRepo,
		bookingRepo: bookingRepo,
		hub:         hub,
	}
}

func (s *service) SendMessage(ctx context.Context, userID uint, userRole string, req SendMessageReq) (*ChatMessage, error) {

	bk, err := s.bookingRepo.FindByID(ctx, req.BookingID)
	if err != nil {
		return nil, apperrors.NewNotFound("ไม่พบข้อมูลการจอง (Booking Not Found)")
	}

	var receiverID uint
	if userRole == "technician" {
		if bk.TechnicianID != userID {
			return nil, apperrors.NewForbidden("คุณไม่ใช่ช่างผู้รับผิดชอบงานนี้")
		}
		receiverID = bk.CustomerID
	} else if userRole == "customer" {
		if bk.CustomerID != userID {
			return nil, apperrors.NewForbidden("คุณไม่ใช่ลูกค้าเจ้าของงานนี้")
		}
		receiverID = bk.TechnicianID
	} else {
		return nil, apperrors.NewBadRequest("Invalid role")
	}

	if !canChat(bk.Status) {
		return nil, apperrors.NewUnprocessable("ไม่สามารถส่งข้อความได้ในสถานะ: " + bk.Status)
	}

	msg := &ChatMessage{
		BookingID:  req.BookingID,
		SenderID:   userID,
		SenderRole: userRole,
		Type:       req.Type,
		Content:    req.Content,
		IsRead:     false,
		CreatedAt:  time.Now(),
	}

	if err := s.chatRepo.Create(ctx, msg); err != nil {
		return nil, apperrors.NewInternal(err)
	}

	eventPayload := realtime.MarshalEvent("NEW_MESSAGE", msg)

	if userRole == "technician" {
		s.hub.BroadcastToCustomer(receiverID, eventPayload)
	} else {
		s.hub.BroadcastToTechnician(receiverID, eventPayload)
	}

	return msg, nil
}

func (s *service) GetChatHistory(ctx context.Context, userID uint, bookingID uint) ([]ChatMessage, error) {

	bk, err := s.bookingRepo.FindByID(ctx, bookingID)
	if err != nil {
		return nil, err
	}

	var userRole string
	if bk.TechnicianID == userID {
		userRole = "technician"
	} else if bk.CustomerID == userID {
		userRole = "customer"
	} else {
		return nil, errors.New("unauthorized")
	}

	msgs, err := s.chatRepo.GetHistory(ctx, bookingID, 0, 100)
	if err != nil {
		return nil, err
	}

	go func() {
		_ = s.chatRepo.MarkAsRead(context.Background(), bookingID, userID, userRole)
	}()

	return msgs, nil
}

func canChat(status string) bool {
	switch status {
	case booking.BookingStatusAccepted,
		booking.BookingStatusInProgress,
		booking.BookingStatusWaitingPayment:
		return true
	default:

		return false
	}
}

func (s *service) GetChatRooms(ctx context.Context, userID uint, userRole string) ([]ChatRoomResponse, error) {
	return s.chatRepo.GetChatRooms(ctx, userID, userRole)
}
