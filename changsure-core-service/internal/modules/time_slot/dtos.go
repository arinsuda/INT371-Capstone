package timeslot

type TimeSlotRequest struct {
	StartTime string `json:"start_time" validate:"required,len=5"`
	EndTime   string `json:"end_time" validate:"required,len=5"`
}

type UpsertTimeSlotsRequest struct {
	Slots []TimeSlotRequest `json:"slots" validate:"required,min=1,dive"`
}
