package notification

import (
	"context"
	"errors"
	"fmt"

	"changsure-core-service/internal/realtime"
)


type Service interface {
	Create(ctx context.Context, in CreateNotificationInput) (*Notification, error)
	Get(ctx context.Context, role RecipientRole, recipientID, id uint) (*Notification, error)
	List(ctx context.Context, role RecipientRole, recipientID uint, q ListQuery) (ListResponse, error)
	Patch(ctx context.Context, role RecipientRole, recipientID, id uint, req PatchRequest) (*Notification, error)
	PatchBulk(ctx context.Context, role RecipientRole, recipientID uint, req PatchBulkRequest) (int64, error)
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
		return nil, ErrInvalidRecipient
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
		return nil, fmt.Errorf("create notification: %w", err)
	}

	s.pushRealtime(in.RecipientRole, in.RecipientID, n)
	return n, nil
}

func (s *service) Get(ctx context.Context, role RecipientRole, recipientID, id uint) (*Notification, error) {
	n, err := s.repo.Get(ctx, role, recipientID, id)
	if err != nil {
		return nil, fmt.Errorf("get notification: %w", err)
	}
	return n, nil
}

func (s *service) List(ctx context.Context, role RecipientRole, recipientID uint, q ListQuery) (ListResponse, error) {
	items, nextCursor, err := s.repo.List(ctx, role, recipientID, q)
	if err != nil {
		return ListResponse{}, fmt.Errorf("list notifications: %w", err)
	}
	return ListResponse{
		Items:      toResponseList(items),
		NextCursor: nextCursor,
		HasMore:    nextCursor != nil,
	}, nil
}

func (s *service) Patch(ctx context.Context, role RecipientRole, recipientID, id uint, req PatchRequest) (*Notification, error) {
	n, err := s.repo.Patch(ctx, role, recipientID, id, *req.IsRead)
	if err != nil {
		return nil, fmt.Errorf("patch notification: %w", err)
	}
	return n, nil
}

func (s *service) PatchBulk(ctx context.Context, role RecipientRole, recipientID uint, req PatchBulkRequest) (int64, error) {
	affected, err := s.repo.PatchBulk(ctx, role, recipientID, req.IDs, *req.IsRead)
	if err != nil {
		return 0, fmt.Errorf("patch bulk notifications: %w", err)
	}
	return affected, nil
}


func (s *service) pushRealtime(role RecipientRole, recipientID uint, n *Notification) {
	if s.hub == nil {
		return
	}
	payload := realtime.MarshalEvent(realtime.EventNotificationNew, map[string]any{
		"notification": toResponse(*n),
	})
	if role == RoleTechnician {
		s.hub.BroadcastToTechnician(recipientID, payload)
	} else {
		s.hub.BroadcastToCustomer(recipientID, payload)
	}
}


func IsNotFound(err error) bool {
	return errors.Is(err, ErrNotFound)
}
