package provider

import (
	"context"
	"time"
)

type OCRResult struct {
	Text       string
	Confidence float64
	Language   string
	Metadata   map[string]interface{}
}

type OCRProvider interface {
	ExtractText(ctx context.Context, imageData []byte, opts *OCROptions) (*OCRResult, error)
	Close() error
	Name() string
}

type OCROptions struct {
	Language string
	PSM      int
	OEM      int
}

type ImageProcessor interface {
	Preprocess(ctx context.Context, imageData []byte, opts *PreprocessOptions) ([]byte, error)
	Normalize(ctx context.Context, imageData []byte) ([]byte, error)
	Upscale(ctx context.Context, imageData []byte, scale float64) ([]byte, error)
	AutoRotate(ctx context.Context, imageData []byte) ([]byte, float64, error)
	ConvertToGrayscale(ctx context.Context, imageData []byte) ([]byte, error)
	EnhanceContrast(ctx context.Context, imageData []byte) ([]byte, error)
}

type PreprocessOptions struct {
	Normalize       bool
	Upscale         float64
	AutoRotate      bool
	Grayscale       bool
	EnhanceContrast bool
}

type Region struct {
	X, Y       float64
	Width      float64
	Height     float64
	Confidence float64
	Type       string
}

type RegionDetector interface {
	DetectIDNumberRegion(ctx context.Context, imageData []byte) (*Region, error)
	DetectNameRegion(ctx context.Context, imageData []byte) (*Region, error)
	DetectAllRegions(ctx context.Context, imageData []byte) ([]*Region, error)
	CropRegion(ctx context.Context, imageData []byte, region *Region) ([]byte, error)
}

type StrategyResult struct {
	Name           string
	Success        bool
	OCRResult      *OCRResult
	ProcessingTime time.Duration
	Error          error
	Metadata       map[string]interface{}
}

type OCRStrategy interface {
	Name() string
	Execute(ctx context.Context, imageData []byte) (*StrategyResult, error)
	Priority() int
	ShouldRetry() bool
}

type CacheKey struct {
	ImageHash string
	Strategy  string
	Language  string
}

type CacheManager interface {
	Get(key *CacheKey) (*OCRResult, bool)
	Set(key *CacheKey, result *OCRResult, ttl time.Duration) error
	Clear() error
}

type MetricsCollector interface {
	RecordStrategyExecution(strategy string, duration time.Duration, success bool)
	RecordOCRConfidence(strategy string, confidence float64)
	RecordError(strategy string, errorType string)
	GetMetrics() map[string]interface{}
}

type ProviderType string

const (
	ProviderTesseract    ProviderType = "tesseract"
	ProviderGoogleVision ProviderType = "google_vision"
	ProviderAWSTextract  ProviderType = "aws_textract"
)

type ProviderFactory interface {
	CreateOCRProvider(providerType ProviderType) (OCRProvider, error)
	CreateImageProcessor() ImageProcessor
	CreateRegionDetector() RegionDetector
}

type DefaultRegionDetector struct {
	idX, idY, idW, idH float64
	idConfidence       float64

	nameX, nameY, nameW, nameH float64
	nameConfidence             float64
}
