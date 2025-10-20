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

	if cfg.TesseractDataPath != "" {
		os.Setenv("TESSDATA_PREFIX", cfg.TesseractDataPath)
	}

	client := gosseract.NewClient()
	defer client.Close()

	if err := client.SetLanguage("eng"); err != nil {
		return nil, fmt.Errorf("tesseract language 'eng' not found. Please install: sudo apt-get install tesseract-ocr-eng")
	}

	return &TesseractProvider{
		config: cfg,
	}, nil
}

func (p *TesseractProvider) ExtractText(ctx context.Context, imageData []byte, opts *OCROptions) (*OCRResult, error) {
	client := gosseract.NewClient()
	defer client.Close()

	language := opts.Language
	if language == "" {
		language = "eng"
	}

	if strings.Contains(language, "tha") {
		language = "eng"
	}

	if err := client.SetLanguage(language); err != nil {

		client.SetLanguage("osd")
	}

	psm := opts.PSM
	if psm == 0 {
		psm = 6
	}

	if psm == 7 {
		psm = 6
	}

	client.SetPageSegMode(gosseract.PageSegMode(psm))

	if strings.Contains(language, "eng") {

		client.SetVariable("tessedit_char_whitelist", "0123456789 -")

		client.SetVariable("classify_bln_numeric_mode", "1")
		client.SetVariable("tessedit_char_blacklist", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
	}

	oem := opts.OEM
	if oem == 0 {
		oem = 3
	}

	client.SetVariable("tessedit_ocr_engine_mode", fmt.Sprintf("%d", oem))

	err := client.SetImageFromBytes(imageData)
	if err != nil {
		return nil, fmt.Errorf("failed to set image: %w", err)
	}

	text, err := client.Text()
	if err != nil {
		return nil, fmt.Errorf("failed to extract text: %w", err)
	}

	if strings.TrimSpace(text) == "" {

		client.SetPageSegMode(gosseract.PSM_SINGLE_WORD)
		if err := client.SetImageFromBytes(imageData); err == nil {
			if retryText, err := client.Text(); err == nil && strings.TrimSpace(retryText) != "" {
				text = retryText
			}
		}
	}

	return &OCRResult{
		Text:       strings.TrimSpace(text),
		Confidence: 0.85,
		Language:   language,
		Metadata: map[string]interface{}{
			"psm": psm,
			"oem": oem,
		},
	}, nil
}

func (p *TesseractProvider) Close() error {
	return nil
}

func (p *TesseractProvider) Name() string {
	return "tesseract"
}
