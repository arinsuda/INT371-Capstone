package timeslot

import (
	"context"
	"fmt"
)

type Service interface {
	GetAllTimeSlots(ctx context.Context) ([]TimeSlotResponse, error)
	GetTimeSlot(ctx context.Context, id uint) (*TimeSlot, error)

	GetMyTimeSlots(ctx context.Context, technicianID uint) ([]TimeSlotResponse, error)
	UpdateMyTimeSlots(ctx context.Context, technicianID uint, req UpsertTimeSlotsRequest) error
	ResetMyTimeSlots(ctx context.Context, technicianID uint) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) GetAllTimeSlots(ctx context.Context) ([]TimeSlotResponse, error) {
	slots, err := s.repo.FindActive(ctx)
	if err != nil {
		return nil, err
	}
	return s.mapToResponse(slots), nil
}

func (s *service) GetTimeSlot(ctx context.Context, id uint) (*TimeSlot, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *service) GetMyTimeSlots(ctx context.Context, technicianID uint) ([]TimeSlotResponse, error) {
	slots, err := s.repo.GetSlotsForTechnician(ctx, technicianID)
	if err != nil {
		return nil, err
	}
	return s.mapToResponse(slots), nil
}

func (s *service) UpdateMyTimeSlots(ctx context.Context, technicianID uint, req UpsertTimeSlotsRequest) error {

	newSlots := make([]TimeSlot, 0, len(req.Slots))
	for _, item := range req.Slots {
		newSlots = append(newSlots, TimeSlot{
			TechnicianID: &technicianID,
			StartTime:    item.StartTime,
			EndTime:      item.EndTime,
			IsActive:     true,
		})
	}

	return s.repo.ReplaceTechnicianSlots(ctx, technicianID, newSlots)
}

func (s *service) ResetMyTimeSlots(ctx context.Context, technicianID uint) error {
	return s.repo.DeleteTechnicianSlots(ctx, technicianID)
}

func (s *service) mapToResponse(slots []TimeSlot) []TimeSlotResponse {
	responses := make([]TimeSlotResponse, 0, len(slots))
	for _, slot := range slots {
		responses = append(responses, TimeSlotResponse{
			ID:          slot.ID,
			StartTime:   slot.StartTime,
			EndTime:     slot.EndTime,
			DisplayText: fmt.Sprintf("%s - %s", slot.StartTime, slot.EndTime),
		})
	}
	return responses
}
