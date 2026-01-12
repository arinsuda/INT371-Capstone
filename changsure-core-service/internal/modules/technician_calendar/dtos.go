package techniciancalendar

type CalendarQuery struct {
	TechnicianID uint   `query:"technician_id" validate:"required"`
	Month        string `query:"month" validate:"required,len=7"`
}

type CalendarResponse struct {
	Month string              `json:"month"`
	Days  []CalendarDayStatus `json:"days"`
}

type CalendarDayStatus struct {
	Date           string           `json:"date"`
	Status         string           `json:"status"`
	TotalSlots     int              `json:"total_slots"`
	BookedSlots    int              `json:"booked_slots"`
	AvailableSlots int              `json:"available_slots"`
	TimeSlots      []TimeSlotDetail `json:"time_slots"`
}

type TimeSlotDetail struct {
	ID        uint   `json:"id"`
	TimeRange string `json:"time_range"`
	IsBooked  bool   `json:"is_booked"`
}
