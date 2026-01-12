package technicianschedule

type UpdateWeeklyScheduleRequest struct {
	WorkingDays []int `json:"working_days" validate:"required,dive,min=0,max=6"`
}

type CreateLeaveRequest struct {
	Date   string `json:"date" validate:"required,datetime=2006-01-02"`
	Reason string `json:"reason"`
}

type DeleteLeaveRequest struct {
	Date string `query:"date" validate:"required,datetime=2006-01-02"`
}
