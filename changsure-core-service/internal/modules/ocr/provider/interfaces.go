package provider

import (
	"context"
	"time"
)

// ============================================
// 1️⃣ Core OCR Provider Interface
// ============================================

// OCRResult ผลลัพธ์จาก OCR
type OCRResult struct {
	Text       string
	Confidence float64
	Language   string
	Metadata   map[string]interface{}
}

// OCRProvider interface หลักสำหรับ text extraction
type OCRProvider interface {
	ExtractText(ctx context.Context, imageData []byte, opts *OCROptions) (*OCRResult, error)
	Close() error
	Name() string
}

// OCROptions ตัวเลือกสำหรับ OCR
type OCROptions struct {
	Language string
	PSM      int
	OEM      int
}

// ============================================
// 2️⃣ Image Processor Interface
// ============================================

// ImageProcessor interface สำหรับ image preprocessing
type ImageProcessor interface {
	Preprocess(ctx context.Context, imageData []byte, opts *PreprocessOptions) ([]byte, error)
	Normalize(ctx context.Context, imageData []byte) ([]byte, error)
	Upscale(ctx context.Context, imageData []byte, scale float64) ([]byte, error)
	AutoRotate(ctx context.Context, imageData []byte) ([]byte, float64, error)
	ConvertToGrayscale(ctx context.Context, imageData []byte) ([]byte, error)
	EnhanceContrast(ctx context.Context, imageData []byte) ([]byte, error)
}

// PreprocessOptions ตัวเลือกสำหรับ preprocessing
type PreprocessOptions struct {
	Normalize      bool
	Upscale        float64
	AutoRotate     bool
	Grayscale      bool
	EnhanceContrast bool
}

// ============================================
// 3️⃣ Region Detector Interface
// ============================================

// Region พื้นที่ในภาพ
type Region struct {
	X          float64 // 0.0 - 1.0
	Y          float64 // 0.0 - 1.0
	Width      float64 // 0.0 - 1.0
	Height     float64 // 0.0 - 1.0
	Confidence float64
	Type       string // "id_number", "name", "photo", etc.
}

// RegionDetector interface สำหรับตรวจจับพื้นที่
type RegionDetector interface {
	DetectIDNumberRegion(ctx context.Context, imageData []byte) (*Region, error)
	DetectNameRegion(ctx context.Context, imageData []byte) (*Region, error)
	DetectAllRegions(ctx context.Context, imageData []byte) ([]*Region, error)
	CropRegion(ctx context.Context, imageData []byte, region *Region) ([]byte, error)
}

// ============================================
// 4️⃣ Strategy Interface
// ============================================

// StrategyResult ผลลัพธ์จาก strategy
type StrategyResult struct {
	Name           string
	Success        bool
	OCRResult      *OCRResult
	ProcessingTime time.Duration
	Error          error
	Metadata       map[string]interface{}
}

// OCRStrategy interface สำหรับ strategy pattern
type OCRStrategy interface {
	Name() string
	Execute(ctx context.Context, imageData []byte) (*StrategyResult, error)
	Priority() int
	ShouldRetry() bool
}

// ============================================
// 5️⃣ Cache Interface
// ============================================

// CacheKey สำหรับ cache
type CacheKey struct {
	ImageHash string
	Strategy  string
	Language  string
}

// CacheManager interface สำหรับ caching
type CacheManager interface {
	Get(key *CacheKey) (*OCRResult, bool)
	Set(key *CacheKey, result *OCRResult, ttl time.Duration) error
	Clear() error
}

// ============================================
// 6️⃣ Metrics Interface
// ============================================

// MetricsCollector interface สำหรับเก็บ metrics
type MetricsCollector interface {
	RecordStrategyExecution(strategy string, duration time.Duration, success bool)
	RecordOCRConfidence(strategy string, confidence float64)
	RecordError(strategy string, errorType string)
	GetMetrics() map[string]interface{}
}

// ============================================
// 7️⃣ Provider Types
// ============================================

type ProviderType string

const (
	ProviderTesseract    ProviderType = "tesseract"
	ProviderGoogleVision ProviderType = "google_vision"
	ProviderAWSTextract  ProviderType = "aws_textract"
)

// ProviderFactory สร้าง providers
type ProviderFactory interface {
	CreateOCRProvider(providerType ProviderType) (OCRProvider, error)
	CreateImageProcessor() ImageProcessor
	CreateRegionDetector() RegionDetector
}