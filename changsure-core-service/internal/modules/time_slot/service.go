package timeslot

import (
	"context"
	"fmt"
)

type Service interface {
	GetAllTimeSlots(ctx context.Context) ([]TimeSlotResponse, error)
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

	responses := make([]TimeSlotResponse, 0, len(slots))
	for _, slot := range slots {
		responses = append(responses, TimeSlotResponse{
			ID:          slot.ID,
			StartTime:   slot.StartTime,
			EndTime:     slot.EndTime,
			DisplayText: fmt.Sprintf("%s - %s", slot.StartTime, slot.EndTime),
		})
	}
	return responses, nil
}
