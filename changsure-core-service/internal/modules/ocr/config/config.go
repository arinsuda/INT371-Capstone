package config

import (
	"os"
	"strconv"
	"time"
)

type OCRConfig struct {
	Provider          string
	TesseractPath     string
	TesseractDataPath string
	Language          string

	AllowFallback bool
	PSM           int
	OEM           int

	MaxFileSize    int64
	MinWidth       int
	MinHeight      int
	MaxWidth       int
	MaxHeight      int
	AllowedFormats []string

	ConfidenceMin     float64
	ConfidenceWarning float64
	MinConfidenceStop float64
	StopOnSuccess     bool
	ValidateChecksum  bool
	EnableMetrics   bool

	TimeoutSec int

	IDCard IDCardConfig

	Performance PerformanceConfig

	Strategies StrategyConfig
}

type IDCardConfig struct {
	PSM              int
	EnableAutoRotate bool
	EnableNormalize  bool
	UpscaleFactor    float64

	IDNumberRegion RegionConfig
	NameRegion     RegionConfig
	PhotoRegion    RegionConfig

	ValidateChecksum     bool
	StrictValidation     bool
	AllowMalformedFormat bool
}

type RegionConfig struct {
	Enabled bool
	X       float64
	Y       float64
	Width   float64
	Height  float64
}

type PerformanceConfig struct {
	EnableConcurrent bool
	MaxConcurrency   int
	StrategyTimeout  time.Duration
	TotalTimeout     time.Duration
	EnableCache      bool
	CacheTTL         time.Duration
	MaxCacheSize     int64
	EnableMetrics    bool
}

type StrategyConfig struct {
	EnableAggressiveCrop   bool
	EnableFullImage        bool
	EnableCroppedRegion    bool
	EnableNormalizedImage  bool
	EnableAutoDetectRegion bool

	ExecutionOrder []string

	StopOnFirstSuccess  bool
	MinConfidenceToStop float64
}

func LoadOCRConfig() *OCRConfig {
	return &OCRConfig{

		Provider:          getEnv("OCR_PROVIDER", "tesseract"),
		TesseractPath:     getEnv("TESSERACT_PATH", "tesseract"),
		TesseractDataPath: getEnv("TESSDATA_PREFIX", "/opt/homebrew/share/tessdata/"),
		Language:          getEnv("OCR_LANGUAGE", "tha+eng"),
		PSM:               getEnvAsInt("OCR_PSM", 6),
		OEM:               getEnvAsInt("OCR_OEM", 3),

		MaxFileSize:    getEnvAsInt64("MAX_FILE_SIZE", 10*1024*1024),
		MinWidth:       getEnvAsInt("MIN_IMAGE_WIDTH", 300),
		MinHeight:      getEnvAsInt("MIN_IMAGE_HEIGHT", 200),
		MaxWidth:       getEnvAsInt("MAX_IMAGE_WIDTH", 5000),
		MaxHeight:      getEnvAsInt("MAX_IMAGE_HEIGHT", 5000),
		AllowedFormats: []string{"image/jpeg", "image/jpg", "image/png", "image/webp"},

		ConfidenceMin:     getEnvAsFloat("OCR_CONFIDENCE_MIN", 0.6),
		ConfidenceWarning: getEnvAsFloat("OCR_CONFIDENCE_WARNING", 0.75),

		IDCard: IDCardConfig{
			PSM:              getEnvAsInt("OCR_ID_CARD_PSM", 6),
			EnableAutoRotate: getEnvAsBool("OCR_AUTO_ROTATE", true),
			EnableNormalize:  getEnvAsBool("OCR_NORMALIZE", true),
			UpscaleFactor:    getEnvAsFloat("OCR_UPSCALE_FACTOR", 2.0),

			IDNumberRegion: RegionConfig{
				Enabled: true,
				X:       getEnvAsFloat("OCR_ID_CROP_X", 0.30),
				Y:       getEnvAsFloat("OCR_ID_CROP_Y", 0.12),
				Width:   getEnvAsFloat("OCR_ID_CROP_W", 0.55),
				Height:  getEnvAsFloat("OCR_ID_CROP_H", 0.08),
			},

			NameRegion: RegionConfig{
				Enabled: false,
			},

			PhotoRegion: RegionConfig{
				Enabled: false,
			},

			ValidateChecksum:     getEnvAsBool("OCR_VALIDATE_CHECKSUM", true),
			StrictValidation:     getEnvAsBool("OCR_STRICT_VALIDATION", false),
			AllowMalformedFormat: getEnvAsBool("OCR_ALLOW_MALFORMED", true),
		},

		Performance: PerformanceConfig{
			EnableConcurrent: getEnvAsBool("OCR_CONCURRENT", true),
			MaxConcurrency:   getEnvAsInt("OCR_MAX_CONCURRENCY", 3),
			StrategyTimeout:  getEnvAsDuration("OCR_STRATEGY_TIMEOUT", 5*time.Second),
			TotalTimeout:     getEnvAsDuration("OCR_TOTAL_TIMEOUT", 15*time.Second),
			EnableCache:      getEnvAsBool("OCR_ENABLE_CACHE", true),
			CacheTTL:         getEnvAsDuration("OCR_CACHE_TTL", 5*time.Minute),
			MaxCacheSize:     getEnvAsInt64("OCR_MAX_CACHE_SIZE", 100*1024*1024),
			EnableMetrics:    getEnvAsBool("OCR_ENABLE_METRICS", true),
		},

		Strategies: StrategyConfig{
			EnableAggressiveCrop:   getEnvAsBool("OCR_STRATEGY_AGGRESSIVE", true),
			EnableFullImage:        getEnvAsBool("OCR_STRATEGY_FULL", true),
			EnableCroppedRegion:    getEnvAsBool("OCR_STRATEGY_CROPPED", true),
			EnableNormalizedImage:  getEnvAsBool("OCR_STRATEGY_NORMALIZED", true),
			EnableAutoDetectRegion: getEnvAsBool("OCR_STRATEGY_AUTO_DETECT", false),

			ExecutionOrder: []string{"cropped", "full", "normalized", "auto_detect"},

			StopOnFirstSuccess:  getEnvAsBool("OCR_STOP_ON_SUCCESS", true),
			MinConfidenceToStop: getEnvAsFloat("OCR_MIN_CONFIDENCE_STOP", 0.85),
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intVal, err := strconv.Atoi(value); err == nil {
			return intVal
		}
	}
	return defaultValue
}

func getEnvAsInt64(key string, defaultValue int64) int64 {
	if value := os.Getenv(key); value != "" {
		if intVal, err := strconv.ParseInt(value, 10, 64); err == nil {
			return intVal
		}
	}
	return defaultValue
}

func getEnvAsFloat(key string, defaultValue float64) float64 {
	if value := os.Getenv(key); value != "" {
		if floatVal, err := strconv.ParseFloat(value, 64); err == nil {
			return floatVal
		}
	}
	return defaultValue
}

func getEnvAsBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		switch value {
		case "true", "1", "yes", "on":
			return true
		case "false", "0", "no", "off":
			return false
		}
	}
	return defaultValue
}

func getEnvAsDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	return defaultValue
}
