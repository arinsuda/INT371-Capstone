package techniciancalendar

type CalendarQuery struct {
	TechnicianID uint   `query:"technician_id" validate:"required"`
	Month        string `query:"month" validate:"required,len=7"` // Format: YYYY-MM
}

type CalendarResponse struct {
	Month string              `json:"month"`
	Days  []CalendarDayStatus `json:"days"`
}

type CalendarDayStatus struct {
	Date           string           `json:"date"`            // 2026-03-08
	Status         string           `json:"status"`          // AVAILABLE, FULL, CLOSED
	TotalSlots     int              `json:"total_slots"`     // จำนวนคิวที่รับได้ทั้งหมด
	BookedSlots    int              `json:"booked_slots"`    // จองไปแล้วกี่คิว
	AvailableSlots int              `json:"available_slots"` // เหลือว่างกี่คิว
	TimeSlots      []TimeSlotDetail `json:"time_slots"`      // รายละเอียดเวลา (Frontend ไม่ต้องยิงขอเพิ่ม)
}

type TimeSlotDetail struct {
	ID        uint   `json:"id"`
	TimeRange string `json:"time_range"` // 08:00 - 09:00
	IsBooked  bool   `json:"is_booked"`
}
