package notification

import (
	"context"
	"errors"

	"changsure-core-service/internal/realtime"
)

type Service interface {
	Create(ctx context.Context, in CreateNotificationInput) (*Notification, error)
	List(ctx context.Context, role RecipientRole, recipientID uint, q ListQuery) ([]Notification, uint, error)
	UnreadCount(ctx context.Context, role RecipientRole, recipientID uint) (int64, error)
	MarkRead(ctx context.Context, role RecipientRole, recipientID uint, ids []uint) (int64, error)
	ReadAll(ctx context.Context, role RecipientRole, recipientID uint) (int64, error)
}

type service struct {
	repo Repository
	hub  *realtime.Hub
}

func NewService(repo Repository, hub *realtime.Hub) Service {
	return &service{repo: repo, hub: hub}
}

func (s *service) Create(ctx context.Context, in CreateNotificationInput) (*Notification, error) {
	if !in.RecipientRole.Valid() || in.RecipientID == 0 {
		return nil, errors.New("invalid recipient")
	}
	if in.Data == nil {
		in.Data = map[string]any{}
	}

	n := &Notification{
		RecipientRole: in.RecipientRole,
		RecipientID:   in.RecipientID,
		Type:          in.Type,
		Title:         in.Title,
		Message:       in.Message,
		EntityType:    in.EntityType,
		EntityID:      in.EntityID,
		Data:          JSONMap(in.Data),
	}

	if err := s.repo.Create(ctx, n); err != nil {
		return nil, err
	}

	if s.hub != nil {
		payload := realtime.MarshalEvent("NOTIFICATION_NEW", map[string]any{
			"notification": n,
		})
		if in.RecipientRole == RoleTechnician {
			s.hub.BroadcastToTechnician(in.RecipientID, payload)
		} else {
			s.hub.BroadcastToCustomer(in.RecipientID, payload)
		}
	}

	return n, nil
}

func (s *service) List(ctx context.Context, role RecipientRole, recipientID uint, q ListQuery) ([]Notification, uint, error) {
	return s.repo.List(ctx, role, recipientID, q)
}

func (s *service) UnreadCount(ctx context.Context, role RecipientRole, recipientID uint) (int64, error) {
	return s.repo.UnreadCount(ctx, role, recipientID)
}

func (s *service) MarkRead(ctx context.Context, role RecipientRole, recipientID uint, ids []uint) (int64, error) {
	return s.repo.MarkRead(ctx, role, recipientID, ids)
}

func (s *service) ReadAll(ctx context.Context, role RecipientRole, recipientID uint) (int64, error) {
	return s.repo.ReadAll(ctx, role, recipientID)
}
