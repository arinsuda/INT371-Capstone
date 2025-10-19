package provider

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"changsure-core-service/internal/modules/ocr/config"
)

type TesseractExecProvider struct {
	config *config.OCRConfig
}

func NewTesseractExecProvider(cfg *config.OCRConfig) (OCRProvider, error) {
	return &TesseractExecProvider{config: cfg}, nil
}

func (p *TesseractExecProvider) ExtractText(ctx context.Context, imageData []byte, opts *OCROptions) (*OCRResult, error) {
	// สร้าง temp file
	tempFile, err := os.CreateTemp("", "ocr-*.png")
	if err != nil {
		return nil, err
	}
	defer os.Remove(tempFile.Name())
	
	if _, err := tempFile.Write(imageData); err != nil {
		return nil, err
	}
	tempFile.Close()

	// Output file
	outputBase := filepath.Join(os.TempDir(), fmt.Sprintf("ocr-%d", os.Getpid()))
	defer os.Remove(outputBase + ".txt")

	// Build command
	args := []string{
		tempFile.Name(),
		outputBase,
		"--psm", fmt.Sprintf("%d", opts.PSM),
		"-l", opts.Language,
		"--tessdata-dir", p.config.TesseractDataPath, // 🆕 เพิ่มบรรทัดนี้
	}

	cmd := exec.CommandContext(ctx, p.config.TesseractPath, args...)
	
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("tesseract error: %w, stderr: %s", err, stderr.String())
	}

	// อ่าน result
	data, err := os.ReadFile(outputBase + ".txt")
	if err != nil {
		return nil, err
	}

	return &OCRResult{
		Text:       strings.TrimSpace(string(data)),
		Confidence: 0.85,
		Language:   opts.Language,
		Metadata:   map[string]interface{}{"psm": opts.PSM},
	}, nil
}

func (p *TesseractExecProvider) Close() error { return nil }
func (p *TesseractExecProvider) Name() string { return "tesseract-exec" }