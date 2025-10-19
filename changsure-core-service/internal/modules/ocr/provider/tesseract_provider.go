package provider

import (
	"context"
	"fmt"
	"os"
	"strings"

	"changsure-core-service/internal/modules/ocr/config"

	"github.com/otiai10/gosseract/v2"
)

type TesseractProvider struct {
	config *config.OCRConfig
}

func NewTesseractProvider(cfg *config.OCRConfig) (OCRProvider, error) {
	// 🆕 Set TESSDATA_PREFIX environment variable
	if cfg.TesseractDataPath != "" {
		os.Setenv("TESSDATA_PREFIX", cfg.TesseractDataPath)
	}
	
	return &TesseractProvider{
		config: cfg,
	}, nil
}

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
		psm = 6
	}
	client.SetPageSegMode(gosseract.PageSegMode(psm))

	// ถ้าเป็นการอ่านเลขบัตร
	if psm == 7 && strings.Contains(language, "eng") && !strings.Contains(language, "tha") {
		client.SetVariable("tessedit_char_whitelist", "0123456789 -")
	}

	// Load image
	err := client.SetImageFromBytes(imageData)
	if err != nil {
		return nil, fmt.Errorf("failed to set image: %w", err)
	}

	// Extract text
	text, err := client.Text()
	if err != nil {
		return nil, fmt.Errorf("failed to extract text: %w", err)
	}

	return &OCRResult{
		Text:       strings.TrimSpace(text),
		Confidence: 0.85, // Default confidence
		Language:   language,
		Metadata: map[string]interface{}{
			"psm": psm,
			"oem": opts.OEM,
		},
	}, nil
}

func (p *TesseractProvider) Close() error {
	return nil
}

func (p *TesseractProvider) Name() string {
	return "tesseract"
}