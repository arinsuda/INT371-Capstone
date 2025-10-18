package dto

import "time"

// OCRResponse response หลัก
type OCRResponse struct {
	Success   bool           `json:"success"`
	Data      *OCRData       `json:"data,omitempty"`
	Error     *ErrorResponse `json:"error,omitempty"`
	Metadata  *Metadata      `json:"metadata,omitempty"`
	Timestamp time.Time      `json:"timestamp"`
}

// OCRData ข้อมูล OCR ทั่วไป
type OCRData struct {
	RawText    string   `json:"raw_text"`
	Confidence float64  `json:"confidence"`
	Language   string   `json:"language,omitempty"`
	IsValid    bool     `json:"is_valid"`
	Warnings   []string `json:"warnings,omitempty"`
}

// IDCardData ข้อมูลบัตรประชาชน
type IDCardData struct {
	OCRData
	
	// Required field
	IDNumber string `json:"id_number"`
	
	// Optional fields
	NameTH        string    `json:"name_th,omitempty"`
	NameEN        string    `json:"name_en,omitempty"`
	DateOfBirth   string    `json:"date_of_birth,omitempty"`
	Address       string    `json:"address,omitempty"`
	IssueDate     string    `json:"issue_date,omitempty"`
	ExpiryDate    string    `json:"expiry_date,omitempty"`
	
	// Validation
	ChecksumValid bool      `json:"checksum_valid"`
	FormatValid   bool      `json:"format_valid"`
	
	// Detection info
	DetectedRegions []DetectedRegion `json:"detected_regions,omitempty"`
}

// DetectedRegion ข้อมูลพื้นที่ที่ตรวจพบ
type DetectedRegion struct {
	Type       string  `json:"type"` // "id_number", "name", "photo", etc.
	X          float64 `json:"x"`
	Y          float64 `json:"y"`
	Width      float64 `json:"width"`
	Height     float64 `json:"height"`
	Confidence float64 `json:"confidence"`
}

// Metadata ข้อมูล metadata
type Metadata struct {
	ProcessingTime  int64              `json:"processing_time_ms"`
	StrategyUsed    string             `json:"strategy_used,omitempty"`
	TotalStrategies int                `json:"total_strategies"`
	ImageInfo       *ImageInfo         `json:"image_info,omitempty"`
	StrategyResults []StrategyResult   `json:"strategy_results,omitempty"`
	Version         string             `json:"version,omitempty"`
}

// ImageInfo ข้อมูลภาพ
type ImageInfo struct {
	Width           int     `json:"width"`
	Height          int     `json:"height"`
	Format          string  `json:"format"`
	Size            int64   `json:"size"`
	WasRotated      bool    `json:"was_rotated,omitempty"`
	RotationAngle   float64 `json:"rotation_angle,omitempty"`
	WasPreprocessed bool    `json:"was_preprocessed"`
}

// StrategyResult ผลลัพธ์จากแต่ละ strategy
type StrategyResult struct {
	Name           string  `json:"name"`
	Success        bool    `json:"success"`
	Confidence     float64 `json:"confidence,omitempty"`
	ProcessingTime int64   `json:"processing_time_ms"`
	Error          string  `json:"error,omitempty"`
	IDFound        bool    `json:"id_found,omitempty"`
}

// ErrorResponse error response
type ErrorResponse struct {
	Code    string                 `json:"code"`
	Message string                 `json:"message"`
	Details map[string]interface{} `json:"details,omitempty"`
}

// ============================================
// 3️⃣ Helper Functions
// ============================================

func NewSuccessResponse(data *OCRData) *OCRResponse {
	return &OCRResponse{
		Success:   true,
		Data:      data,
		Timestamp: time.Now(),
	}
}

func NewIDCardSuccessResponse(data *IDCardData, metadata *Metadata) *OCRResponse {
	return &OCRResponse{
		Success: true,
		Data: &OCRData{
			RawText:    data.RawText,
			Confidence: data.Confidence,
			Language:   data.Language,
			IsValid:    data.IsValid,
			Warnings:   data.Warnings,
		},
		Metadata:  metadata,
		Timestamp: time.Now(),
	}
}

func NewErrorResponse(code, message string) *OCRResponse {
	return &OCRResponse{
		Success: false,
		Error: &ErrorResponse{
			Code:    code,
			Message: message,
		},
		Timestamp: time.Now(),
	}
}

func NewErrorResponseWithDetails(code, message string, details map[string]interface{}) *OCRResponse {
	return &OCRResponse{
		Success: false,
		Error: &ErrorResponse{
			Code:    code,
			Message: message,
			Details: details,
		},
		Timestamp: time.Now(),
	}
}

// ============================================
// 4️⃣ Error Codes
// ============================================

const (
	ErrCodeInvalidInput     = "INVALID_INPUT"
	ErrCodeFileTooLarge     = "FILE_TOO_LARGE"
	ErrCodeInvalidFormat    = "INVALID_FORMAT"
	ErrCodeProcessingFailed = "PROCESSING_FAILED"
	ErrCodeOCRFailed        = "OCR_FAILED"
	ErrCodeNoIDFound        = "NO_ID_FOUND"
	ErrCodeInvalidChecksum  = "INVALID_CHECKSUM"
	ErrCodeTimeout          = "TIMEOUT"
	ErrCodeInternalError    = "INTERNAL_ERROR"
)