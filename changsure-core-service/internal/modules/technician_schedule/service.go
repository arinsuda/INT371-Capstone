package technicianschedule

import (
	"context"
	"time"
)

type Service interface {
	UpdateWeeklySchedule(ctx context.Context, techID uint, req UpdateWeeklyScheduleRequest) error
	GetWeeklySchedule(ctx context.Context, techID uint) ([]int, error)

	AddLeaveDate(ctx context.Context, techID uint, req CreateLeaveRequest) error
	RemoveLeaveDate(ctx context.Context, techID uint, dateStr string) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) UpdateWeeklySchedule(ctx context.Context, techID uint, req UpdateWeeklyScheduleRequest) error {
	// อาจจะมีการ Validate เพิ่มเติมที่นี่ เช่น ห้ามส่งเลขซ้ำ หรือเลขเกิน 6 (แต่ Validator ใน Struct จัดการให้แล้วส่วนหนึ่ง)
	return s.repo.UpdateWeeklySchedule(ctx, techID, req.WorkingDays)
}

func (s *service) GetWeeklySchedule(ctx context.Context, techID uint) ([]int, error) {
	return s.repo.GetWeeklySchedule(ctx, techID)
}

func (s *service) AddLeaveDate(ctx context.Context, techID uint, req CreateLeaveRequest) error {
	date, err := time.Parse("2006-01-02", req.Date)
	if err != nil {
		return err // ควรจะผ่าน Validate มาแล้ว
	}

	leave := &LeaveDate{
		TechnicianID: techID,
		Date:         date,
		Reason:       req.Reason,
	}
	return s.repo.AddLeaveDate(ctx, leave)
}

func (s *service) RemoveLeaveDate(ctx context.Context, techID uint, dateStr string) error {
	return s.repo.RemoveLeaveDate(ctx, techID, dateStr)
}
