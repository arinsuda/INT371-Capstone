package criminalcheck

import "time"

type VerifyIdentityResponse struct {
	TechnicianID  uint        `json:"technician_id"`
	NationalID    string      `json:"national_id"`
	ExtractedName string      `json:"extracted_name,omitempty"`
	SystemName    string      `json:"system_name,omitempty"`
	Status        CheckStatus `json:"status"`
	Note          string      `json:"note"`
	Message       string      `json:"message"`
}

type ListLogsFilter struct {
	Status     string `query:"status"`
	NationalID string `query:"national_id"`
	TechName   string `query:"tech_name"`
	DateFrom   string `query:"date_from"`
	DateTo     string `query:"date_to"`
	Page       int    `query:"page"`
	PageSize   int    `query:"page_size"`
}

type VerificationLogResponse struct {
	ID              uint                       `json:"id"`
	TechnicianID    uint                       `json:"technician_id"`
	TechnicianName  string                     `json:"technician_name"`
	NationalID      string                     `json:"national_id"`
	Status          CheckStatus                `json:"status"`
	Note            string                     `json:"note"`
	RawOCRText      string                     `json:"raw_ocr_text,omitempty"`
	IDCardImageURL  *string                    `json:"id_card_image_url,omitempty"`
	CreatedAt       time.Time                  `json:"created_at"`
	OverrideHistory []AdminOverrideLogResponse `json:"override_history,omitempty"`
}

type ListLogsResponse struct {
	Logs     []VerificationLogResponse `json:"logs"`
	Total    int64                     `json:"total"`
	Page     int                       `json:"page"`
	PageSize int                       `json:"page_size"`
}

type UpdateLogStatusRequest struct {
	Status CheckStatus `validate:"required,oneof=PASSED FAILED PENDING OCR_FAILED NAME_NOT_EXTRACTED"`
	Reason string      `json:"reason" validate:"required,min=5,max=500"`
}

type OverrideVerificationStatusRequest struct {
	Status CheckStatus `json:"status" validate:"required,oneof=PASSED FAILED PENDING"`
	Reason string      `json:"reason" validate:"required,min=5,max=500"`
}

type AdminOverrideLogResponse struct {
	ID            uint      `json:"id"`
	AdminID       uint      `json:"admin_id"`
	TargetType    string    `json:"target_type"`
	PreviousValue string    `json:"previous_value"`
	NewValue      string    `json:"new_value"`
	Reason        string    `json:"reason"`
	CreatedAt     time.Time `json:"created_at"`
}

type VerificationStatResponse struct {
	Total   int64 `json:"total"`
	Passed  int64 `json:"passed"`
	Failed  int64 `json:"failed"`
	Pending int64 `json:"pending"`
}

type CreateCriminalRecordRequest struct {
	NationalID string `json:"national_id" validate:"required,len=13,numeric"`
	FullName   string `json:"full_name"   validate:"required,min=2,max=200"`
	Note       string `json:"note"        validate:"required,min=2,max=500"`
}

type UpdateCriminalRecordRequest struct {
	NationalID *string `json:"national_id" validate:"omitempty,len=13,numeric"`
	FullName   *string `json:"full_name"   validate:"omitempty,min=2,max=200"`
	Note       *string `json:"note"        validate:"omitempty,min=2,max=500"`
}

type CriminalRecordResponse struct {
	ID         uint        `json:"id"`
	NationalID string      `json:"national_id"`
	FullName   string      `json:"full_name"`
	Status     CheckStatus `json:"status"`
	Note       string      `json:"note"`
	CreatedAt  time.Time   `json:"created_at"`
	UpdatedAt  time.Time   `json:"updated_at"`
}

type JobStatusResponse struct {
	JobID        uint       `json:"job_id"`
	Status       string     `json:"status"`
	RetryCount   int        `json:"retry_count"`
	ErrorMsg     string     `json:"error_msg,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
	StartedAt    *time.Time `json:"started_at,omitempty"`
	FinishedAt   *time.Time `json:"finished_at,omitempty"`
	VerifyStatus string     `json:"verify_status,omitempty"`
	VerifyNote   string     `json:"verify_note,omitempty"`
}

type TechnicianVerificationDetail struct {
	TechnicianID       uint                     `json:"technician_id"`
	FirstName          string                   `json:"first_name"`
	LastName           string                   `json:"last_name"`
	Email              *string                  `json:"email"`
	Phone              *string                  `json:"phone"`
	AvatarURL          *string                  `json:"avatar_url"`
	ServiceNames       []string                 `json:"service_names"`
	ProvinceNames      []string                 `json:"province_names"`
	RegisteredAt       int64                    `json:"registered_at"`
	VerificationStatus string                   `json:"verification_status"`
	NationalID         *string                  `json:"national_id"`
	ExtractedName      *string                  `json:"extracted_name"`
	IDCardImageURL     *string                  `json:"id_card_image_url"`
	CriminalRecord     *CriminalRecordResponse  `json:"criminal_record"`
	LatestLog          *VerificationLogResponse `json:"latest_log"`
	PendingJobID       *uint                    `json:"pending_job_id,omitempty"`
}
