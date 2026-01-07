package technicianschedule

// Request สำหรับตั้งค่า Pattern รายสัปดาห์
type UpdateWeeklyScheduleRequest struct {
	// ส่งมาเฉพาะวันที่จะทำ เช่น [1, 2, 3, 4, 5] (จันทร์-ศุกร์)
	WorkingDays []int `json:"working_days" validate:"required,dive,min=0,max=6"`
}

// Request สำหรับวันลา
type CreateLeaveRequest struct {
	Date   string `json:"date" validate:"required,datetime=2006-01-02"`
	Reason string `json:"reason"`
}

// Request สำหรับลบวันลา (รับผ่าน Query Params)
type DeleteLeaveRequest struct {
	Date string `query:"date" validate:"required,datetime=2006-01-02"`
}
