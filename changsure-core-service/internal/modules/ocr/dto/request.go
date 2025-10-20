package dto

type OCRRequest struct {
	PreprocessImage bool `json:"preprocess_image" form:"preprocess_image"`
	AutoRotate      bool `json:"auto_rotate" form:"auto_rotate"`
	NormalizeImage  bool `json:"normalize_image" form:"normalize_image"`

	Language string `json:"language" form:"language"`
	PSM      *int   `json:"psm,omitempty" form:"psm"`

	ValidateChecksum bool `json:"validate_checksum" form:"validate_checksum"`
	StrictMode       bool `json:"strict_mode" form:"strict_mode"`

	Timeout          int  `json:"timeout,omitempty" form:"timeout"`
	EnableConcurrent bool `json:"enable_concurrent" form:"enable_concurrent"`

	Strategies    []string `json:"strategies,omitempty" form:"strategies"`
	StopOnSuccess bool     `json:"stop_on_success" form:"stop_on_success"`
	MinConfidence float64  `json:"min_confidence,omitempty" form:"min_confidence"`
}

type IDCardRequest struct {
	OCRRequest

	ExtractName      bool `json:"extract_name" form:"extract_name"`
	ExtractDOB       bool `json:"extract_dob" form:"extract_dob"`
	ExtractAddress   bool `json:"extract_address" form:"extract_address"`
	ExtractIssueDate bool `json:"extract_issue_date" form:"extract_issue_date"`
	ExtractExpiry    bool `json:"extract_expiry" form:"extract_expiry"`

	AutoDetectRegion bool `json:"auto_detect_region" form:"auto_detect_region"`
}

func (r *OCRRequest) SetDefaults() {
	if r.Language == "" {
		r.Language = "tha+eng"
	}
	if r.Timeout == 0 {
		r.Timeout = 15
	}
	if r.MinConfidence == 0 {
		r.MinConfidence = 0.6
	}
	if len(r.Strategies) == 0 {
		r.Strategies = []string{"cropped", "full", "normalized"}
	}
}

func (r *IDCardRequest) SetDefaults() {
	r.OCRRequest.SetDefaults()
	r.ValidateChecksum = true
	r.AutoDetectRegion = false
}
