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

	// สำหรับบัตรไทย: ใช้ eng สำหรับตัวเลข (ทำงานได้ดีกว่า tha สำหรับ ID number)
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

	client.SetPageSegMode(gosseract.PageSegMode(psm))

	// ✅ ปรับปรุง: ลบ whitelist ที่เข้มงวดเกินไป - ให้ Tesseract ทำงานอิสระ
	// เดิม: whitelist เฉพาะ 0-9 ทำให้อ่านผิดเมื่อเจอตัวอักษรคล้ายๆ
	// ใหม่: ไม่จำกัด whitelist แต่ใช้ classify_bln_numeric_mode แทน

	if strings.Contains(language, "eng") {
		// โหมดตัวเลข: ช่วยให้ Tesseract มุ่งเน้นตัวเลขแต่ยังอ่านตัวอักษรที่คล้ายกันได้
		client.SetVariable("classify_bln_numeric_mode", "1")

		// เพิ่มการจัดการกับตัวอักษรที่คล้ายตัวเลข
		client.SetVariable("tessedit_char_blacklist", "")

		// ปรับ confidence สำหรับตัวเลข
		client.SetVariable("classify_enable_adaptive_matcher", "1")
	}

	oem := opts.OEM
	if oem == 0 {
		oem = 3 // Default: Legacy + LSTM
	}

	// ✅ สำหรับ Tesseract 5.x ให้ใช้ OEM 1 (LSTM only) จะแม่นยำกว่า
	if oem == 3 {
		oem = 1 // LSTM only - ทำงานดีกว่าใน Tesseract 5.x
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

	// ✅ เพิ่ม debug logging
	if os.Getenv("OCR_DEBUG") == "true" {
		fmt.Printf("\n=== [DEBUG] OCR Raw Output ===\n")
		fmt.Printf("PSM: %d | OEM: %d | Language: %s\n", psm, oem, language)
		fmt.Printf("Raw Text: %q\n", text)
		fmt.Printf("Text Length: %d chars\n", len(text))
		fmt.Printf("Digits Only: %q\n", extractDigitsForDebug(text))
		fmt.Printf("==============================\n\n")
	}

	// ✅ เพิ่ม fallback: ถ้าไม่ได้ text ลอง PSM อื่น
	if strings.TrimSpace(text) == "" {
		// ลอง PSM 7 (single line) และ PSM 13 (raw line)
		fallbackPSMs := []gosseract.PageSegMode{
			gosseract.PSM_SINGLE_LINE,
			gosseract.PSM_RAW_LINE,
			gosseract.PSM_SINGLE_WORD,
		}

		for _, fallbackPSM := range fallbackPSMs {
			client.SetPageSegMode(fallbackPSM)
			if err := client.SetImageFromBytes(imageData); err == nil {
				if retryText, err := client.Text(); err == nil && strings.TrimSpace(retryText) != "" {
					text = retryText
					psm = int(fallbackPSM)
					break
				}
			}
		}
	}

	// ✅ คำนวณ confidence โดยประมาณจาก text length และ character types
	confidence := p.estimateConfidence(text, psm)

	return &OCRResult{
		Text:       strings.TrimSpace(text),
		Confidence: confidence,
		Language:   language,
		Metadata: map[string]interface{}{
			"psm": psm,
			"oem": oem,
		},
	}, nil
}

// ✅ เพิ่ม: ประมาณ confidence จาก pattern ของ text
func (p *TesseractProvider) estimateConfidence(text string, psm int) float64 {
	if text == "" {
		return 0.0
	}

	confidence := 0.75 // base confidence

	// ถ้ามีตัวเลข 13 หลัก → เพิ่ม confidence
	digitCount := 0
	for _, r := range text {
		if r >= '0' && r <= '9' {
			digitCount++
		}
	}

	if digitCount >= 13 {
		confidence += 0.15
	} else if digitCount >= 10 {
		confidence += 0.05
	}

	// ถ้า text สะอาด (ไม่มีตัวอักษรแปลกๆ มาก) → เพิ่ม confidence
	cleanRatio := float64(digitCount) / float64(len(text))
	if cleanRatio > 0.7 {
		confidence += 0.05
	}

	// PSM 7 (single line) มักแม่นยำกว่า
	if psm == 7 {
		confidence += 0.05
	}

	if confidence > 1.0 {
		confidence = 1.0
	}

	return confidence
}

func (p *TesseractProvider) Close() error {
	return nil
}

func (p *TesseractProvider) Name() string {
	return "tesseract"
}

func extractDigitsForDebug(text string) string {
	var digits string
	for _, r := range text {
		if r >= '0' && r <= '9' {
			digits += string(r)
		}
	}
	return digits
}
