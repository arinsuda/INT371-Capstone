package provider

import (
	"context"
	"strings"

	"changsure-core-service/internal/modules/ocr/config"

	"github.com/otiai10/gosseract/v2"
)

// TesseractProvider implements OCRProvider interface
type TesseractProvider struct {
	config *config.OCRConfig
}

func NewTesseractProvider(cfg *config.OCRConfig) (OCRProvider, error) {
	return &TesseractProvider{
		config: cfg,
	}, nil
}

// ExtractText ดึงข้อความจากภาพ
func (p *TesseractProvider) ExtractText(ctx context.Context, imageData []byte, opts *OCROptions) (*OCRResult, error) {
	client := gosseract.NewClient()
	defer client.Close()

	// ตั้งค่าภาษา
	language := opts.Language
	if language == "" {
		language = "eng"
	}
	client.SetLanguage(language)

	// ตั้งค่า PSM
	psm := opts.PSM
	if psm == 0 {
		psm = 6 // default
	}
	client.SetPageSegMode(gosseract.PageSegMode(psm))

	// ตั้งค่า OEM
	if opts.OEM > 0 {
		client.SetVariable("tessedit_ocr_engine_mode", string(rune(opts.OEM)))
	}

	// ถ้าเป็นการอ่านเลขบัตร ให้ใช้ config พิเศษ
	if psm == 7 && strings.Contains(language, "eng") && !strings.Contains(language, "tha") {
		// Single line mode for numbers
		client.SetVariable("tessedit_char_whitelist", "0123456789 -")
	}

	// Load image
	err := client.SetImageFromBytes(imageData)
	if err != nil {
		return nil, err
	}

	// Extract text
	text, err := client.Text()
	if err != nil {
		return nil, err
	}

	// Get confidence (0-100)
	confidence, _ := client.GetConfidence()
	confidenceNormalized := float64(confidence) / 100.0 // แปลงเป็น 0.0-1.0

	return &OCRResult{
		Text:       strings.TrimSpace(text),
		Confidence: confidenceNormalized,
		Language:   language,
		Metadata: map[string]interface{}{
			"psm": psm,
			"oem": opts.OEM,
		},
	}, nil
}

// Close ปิด provider
func (p *TesseractProvider) Close() error {
	return nil
}

// Name ชื่อของ provider
func (p *TesseractProvider) Name() string {
	return "tesseract"
}