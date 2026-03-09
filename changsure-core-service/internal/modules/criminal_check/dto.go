package criminalcheck

import "time"

type VerifyIdentityResponse struct {
	TechnicianID  uint        `json:"technician_id"`
	NationalID    string      `json:"national_id"`
	ExtractedName string      `json:"extracted_name,omitempty"`
	SystemName    string      `json:"system_name,omitempty"`
	Status        CheckStatus `json:"status"`
	Note          string      `json:"note"`
	IsVerified    bool        `json:"is_verified"`
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
	IsVerified      bool                       `json:"is_verified"`
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
	Status CheckStatus `json:"status" validate:"required,oneof=PASSED FAILED PENDING NOT_FOUND OCR_FAILED NAME_NOT_EXTRACTED"`
	Reason string      `json:"reason" validate:"required,min=5,max=500"`
}

type OverrideIsVerifiedRequest struct {
	IsVerified bool   `json:"is_verified"`
	Reason     string `json:"reason" validate:"required,min=5,max=500"`
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
	Total    int64 `json:"total"`
	Passed   int64 `json:"passed"`
	Failed   int64 `json:"failed"`
	Pending  int64 `json:"pending"`
	NotFound int64 `json:"not_found"`
}

type CreateCriminalRecordRequest struct {
	NationalID string      `json:"national_id" validate:"required,len=13,numeric"`
	FullName   string      `json:"full_name"   validate:"required,min=2,max=200"`
	Status     CheckStatus `json:"status"      validate:"required,oneof=PASSED FAILED PENDING NOT_FOUND"`
	Note       string      `json:"note"        validate:"required,min=2,max=500"`
}

type UpdateCriminalRecordRequest struct {
	FullName *string      `json:"full_name" validate:"omitempty,min=2,max=200"`
	Status   *CheckStatus `json:"status"    validate:"omitempty,oneof=PASSED FAILED PENDING NOT_FOUND"`
	Note     *string      `json:"note"      validate:"omitempty,min=2,max=500"`
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
	JobID      uint       `json:"job_id"`
	Status     string     `json:"status"`
	RetryCount int        `json:"retry_count"`
	ErrorMsg   string     `json:"error_msg,omitempty"`
	CreatedAt  time.Time  `json:"created_at"`
	StartedAt  *time.Time `json:"started_at,omitempty"`
	FinishedAt *time.Time `json:"finished_at,omitempty"`
	VerifyStatus string `json:"verify_status,omitempty"`
	VerifyNote   string `json:"verify_note,omitempty"`
	IsVerified   *bool  `json:"is_verified,omitempty"`
}
