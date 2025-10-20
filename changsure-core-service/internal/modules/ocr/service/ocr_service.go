package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/dto"
	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/strategy"
	"changsure-core-service/internal/modules/ocr/validator"
)

type OCRService struct {
	strategyManager *strategy.StrategyManager
	validator       *validator.IDCardValidator
	metrics         provider.MetricsCollector
	config          *config.OCRConfig
}

func NewOCRService(
	strategyManager *strategy.StrategyManager,
	validator *validator.IDCardValidator,
	metrics provider.MetricsCollector,
	cfg *config.OCRConfig,
) *OCRService {
	return &OCRService{
		strategyManager: strategyManager,
		validator:       validator,
		metrics:         metrics,
		config:          cfg,
	}
}

// ===================== Public APIs =====================

func (s *OCRService) ProcessIDCard(ctx context.Context, imageData []byte, req *dto.IDCardRequest) (*dto.IDCardData, *dto.Metadata, error) {
	start := time.Now()
	if req == nil {
		req = &dto.IDCardRequest{}
	}
	req.SetDefaults()

	// 1) รวมค่ามีผลจริงจาก req + config
	eff := s.effectiveParamsForID(req)

	// 2) ตั้ง timeout
	if eff.timeoutSec > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, time.Duration(eff.timeoutSec)*time.Second)
		defer cancel()
	}

	// 3) เรียกกลยุทธ์ OCR
	execResult, err := s.strategyManager.Execute(ctx, imageData, eff.language)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to execute strategies: %w", err)
	}
	if execResult == nil {
		return nil, nil, errors.New("strategy execution returned nil result")
	}

	// 4) ถ้าไม่มีผลลัพธ์เลย
	if execResult.BestResult == nil {
		return s.createFailedIDResponse(execResult), s.createMetadata(execResult, start), nil
	}

	// 5) Early-accept: ถ้าเปิด stopOnSuccess และความเชื่อมั่นเกินเกณฑ์ ให้เดินหน้าตรวจเลขทันที
	// (หมายเหตุ: StrategyManager ของคุณควรหยุดเองเมื่อเปิด StopOnSuccess อยู่แล้ว แต่เราเช็คซ้ำเผื่อ)
	if eff.stopOnSuccess && execResult.BestResult.Confidence >= eff.minConfidenceStop {
		// proceed
	}

	// 6) ดึงเลขบัตร + ตรวจ checksum
	idNumber, idErr := s.validator.ExtractIDNumber(execResult.BestResult.Text)

	checksumValid := false
	formatValid := false
	warnings := make([]string, 0, 4)

	if idErr == nil && idNumber != "" {
		formatValid = true
		if eff.validateChecksum {
			if err := s.validator.ValidateChecksum(idNumber); err != nil {
				warnings = append(warnings, fmt.Sprintf("Checksum validation failed: %v", err))
			} else {
				checksumValid = true
			}
		} else {
			checksumValid = true
		}
	} else {
		// Fallback: clean แล้วลองหยิบ 13 หลัก
		if eff.allowFallback {
			clean := CleanToAsciiDigits(execResult.BestResult.Text)
			cand := pickBestThaiID(clean, eff.validateChecksum)
			if cand != "" {
				idNumber = cand
				formatValid = true
				if eff.validateChecksum {
					if err := s.validator.ValidateChecksum(idNumber); err != nil {
						warnings = append(warnings, fmt.Sprintf("Checksum validation failed: %v", err))
					} else {
						checksumValid = true
					}
				} else {
					checksumValid = true
				}
			} else {
				warnings = append(warnings, "No valid ID card number detected (after fallback)")
			}
		} else {
			warnings = append(warnings, "No valid ID card number detected")
		}
	}

	// 7) สถานะ valid โดยรวม + เตือนเรื่องความเชื่อมั่นต่ำ
	isValid := checksumValid && formatValid
	if execResult.BestResult.Confidence < eff.confidenceMin {
		warnings = append(warnings, fmt.Sprintf(
			"OCR confidence (%.2f) is below minimum threshold (%.2f)",
			execResult.BestResult.Confidence, eff.confidenceMin,
		))
	}

	idCardData := &dto.IDCardData{
		OCRData: dto.OCRData{
			RawText:    execResult.BestResult.Text,
			Confidence: execResult.BestResult.Confidence,
			Language:   execResult.BestResult.Language,
			IsValid:    isValid,
			Warnings:   warnings,
		},
		IDNumber:      idNumber,
		ChecksumValid: checksumValid,
		FormatValid:   formatValid,
	}

	return idCardData, s.createMetadata(execResult, start), nil
}

func (s *OCRService) ExtractText(ctx context.Context, imageData []byte, req *dto.OCRRequest) (*dto.OCRData, *dto.Metadata, error) {
	start := time.Now()
	if req == nil {
		req = &dto.OCRRequest{}
	}
	req.SetDefaults()

	eff := s.effectiveParamsForOCR(req)

	if eff.timeoutSec > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, time.Duration(eff.timeoutSec)*time.Second)
		defer cancel()
	}

	execResult, err := s.strategyManager.Execute(ctx, imageData, eff.language)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to execute strategies: %w", err)
	}

	if execResult == nil || execResult.BestResult == nil {
		return &dto.OCRData{
			IsValid:  false,
			Warnings: []string{"No text could be extracted"},
		}, s.createMetadata(execResult, start), nil
	}

	warnings := []string{}
	if execResult.BestResult.Confidence < eff.confidenceMin {
		warnings = append(warnings, fmt.Sprintf(
			"OCR confidence (%.2f) is below minimum threshold (%.2f)",
			execResult.BestResult.Confidence, eff.confidenceMin,
		))
	}

	data := &dto.OCRData{
		RawText:    execResult.BestResult.Text,
		Confidence: execResult.BestResult.Confidence,
		Language:   execResult.BestResult.Language,
		IsValid:    execResult.BestResult.Confidence >= eff.confidenceMin,
		Warnings:   warnings,
	}
	return data, s.createMetadata(execResult, start), nil
}

func (s *OCRService) GetMetrics() map[string]interface{} {
	// ✅ ใช้คอนฟิกใหม่ (อยู่ใต้ Performance)
	if s.metrics == nil || s.config == nil || !s.config.Performance.EnableMetrics {
		return nil
	}
	return s.metrics.GetMetrics()
}

func (s *OCRService) Close() error {
	return nil
}

// ===================== Internals =====================

type effectiveParams struct {
	language          string
	confidenceMin     float64
	minConfidenceStop float64
	stopOnSuccess     bool
	validateChecksum  bool
	allowFallback     bool
	timeoutSec        int
}

func (s *OCRService) effectiveParamsForID(req *dto.IDCardRequest) effectiveParams {
	// language: req → cfg.Language
	lang := strings.TrimSpace(req.Language)
	if lang == "" {
		if s.config != nil && strings.TrimSpace(s.config.Language) != "" {
			lang = s.config.Language
		} else {
			lang = "eng"
		}
	}

	// ความเชื่อมั่นขั้นต่ำ: req.MinConfidence → cfg.ConfidenceMin
	cMin := req.MinConfidence
	if cMin <= 0 && s.config != nil && s.config.ConfidenceMin > 0 {
		cMin = s.config.ConfidenceMin
	}
	if cMin <= 0 {
		cMin = 0.20
	}

	// Stop on success:
	// ใช้ req.StopOnSuccess → cfg.StopOnSuccess → cfg.Strategies.StopOnFirstSuccess
	sos := req.StopOnSuccess
	if s.config != nil && !sos {
		if s.config.StopOnSuccess {
			sos = true
		} else if s.config.Strategies.StopOnFirstSuccess {
			sos = true
		}
	}

	// เกณฑ์หยุด: req.MinConfidence (ถ้าตั้ง) → cfg.MinConfidenceStop → cfg.Strategies.MinConfidenceToStop
	minStop := req.MinConfidence
	if s.config != nil && minStop <= 0 {
		if s.config.MinConfidenceStop > 0 {
			minStop = s.config.MinConfidenceStop
		} else if s.config.Strategies.MinConfidenceToStop > 0 {
			minStop = s.config.Strategies.MinConfidenceToStop
		}
	}
	if minStop <= 0 {
		minStop = 0.80
	}

	// ตรวจ checksum: req.ValidateChecksum → cfg.IDCard.ValidateChecksum → cfg.ValidateChecksum
	valChecksum := req.ValidateChecksum
	if s.config != nil {
		if !valChecksum && s.config.IDCard.ValidateChecksum {
			valChecksum = true
		}
		if !valChecksum && s.config.ValidateChecksum {
			valChecksum = true
		}
	}

	// อนุญาต fallback cleaning
	allowFallback := true
	if s.config != nil {
		allowFallback = s.config.AllowFallback
		// ถ้าไม่กำหนดใน .env, default true
		if !s.config.AllowFallback {
			allowFallback = true
		}
	}

	// timeout: req.Timeout → cfg.TimeoutSec → cfg.Performance.TotalTimeout
	tSec := req.Timeout
	if tSec <= 0 && s.config != nil {
		if s.config.TimeoutSec > 0 {
			tSec = s.config.TimeoutSec
		} else if s.config.Performance.TotalTimeout > 0 {
			tSec = int(s.config.Performance.TotalTimeout.Seconds())
		}
	}

	return effectiveParams{
		language:          lang,
		confidenceMin:     cMin,
		minConfidenceStop: minStop,
		stopOnSuccess:     sos,
		validateChecksum:  valChecksum,
		allowFallback:     allowFallback,
		timeoutSec:        tSec,
	}
}

func (s *OCRService) effectiveParamsForOCR(req *dto.OCRRequest) effectiveParams {
	lang := strings.TrimSpace(req.Language)
	if lang == "" {
		if s.config != nil && strings.TrimSpace(s.config.Language) != "" {
			lang = s.config.Language
		} else {
			lang = "tha+eng"
		}
	}

	cMin := req.MinConfidence
	if cMin <= 0 && s.config != nil && s.config.ConfidenceMin > 0 {
		cMin = s.config.ConfidenceMin
	}
	if cMin <= 0 {
		cMin = 0.20
	}

	tSec := req.Timeout
	if tSec <= 0 && s.config != nil {
		if s.config.TimeoutSec > 0 {
			tSec = s.config.TimeoutSec
		} else if s.config.Performance.TotalTimeout > 0 {
			tSec = int(s.config.Performance.TotalTimeout.Seconds())
		}
	}

	return effectiveParams{
		language:      lang,
		confidenceMin: cMin,
		timeoutSec:    tSec,
	}
}

func (s *OCRService) createFailedIDResponse(execResult *strategy.ExecutionResult) *dto.IDCardData {
	warnings := []string{"All strategies failed to extract ID card number"}
	if execResult != nil {
		for _, r := range execResult.StrategyResults {
			if !r.Success && r.Error != nil {
				warnings = append(warnings, fmt.Sprintf("%s: %v", r.Name, r.Error))
			}
		}
	}
	return &dto.IDCardData{
		OCRData: dto.OCRData{
			RawText:  "",
			IsValid:  false,
			Warnings: warnings,
		},
		ChecksumValid: false,
		FormatValid:   false,
	}
}

func (s *OCRService) createMetadata(execResult *strategy.ExecutionResult, start time.Time) *dto.Metadata {
	md := &dto.Metadata{
		ProcessingTime:  time.Since(start).Milliseconds(),
		StrategyUsed:    "",
		TotalStrategies: 0,
		StrategyResults: make([]dto.StrategyResult, 0),
		Version:         "2.0.0",
	}
	if execResult == nil {
		return md
	}

	md.TotalStrategies = len(execResult.StrategyResults)
	for _, r := range execResult.StrategyResults {
		item := dto.StrategyResult{
			Name:           r.Name,
			Success:        r.Success,
			ProcessingTime: r.ProcessingTime.Milliseconds(),
		}
		if r.Success && r.OCRResult != nil {
			item.Confidence = r.OCRResult.Confidence
			if r.Metadata != nil {
				if idFound, ok := r.Metadata["id_found"].(bool); ok {
					item.IDFound = idFound
				}
			}
		}
		if r.Error != nil {
			item.Error = r.Error.Error()
		}
		md.StrategyResults = append(md.StrategyResults, item)

		if execResult.BestResult != nil && r.Success && r.OCRResult == execResult.BestResult {
			md.StrategyUsed = r.Name
		}
	}
	return md
}

// ===================== Utilities (เดิม) =====================

func CleanToAsciiDigits(s string) string {
	repl := strings.NewReplacer(
		"๐", "0", "๑", "1", "๒", "2", "๓", "3", "๔", "4", "๕", "5", "๖", "6", "๗", "7", "๘", "8", "๙", "9",
		"０", "0", "１", "1", "２", "2", "３", "3", "４", "4", "５", "5", "６", "6", "７", "7", "８", "8", "９", "9",
		"O", "0", "o", "0", "I", "1", "l", "1", "B", "8", "S", "5", "Z", "2", "q", "9", "〇", "0",
	)
	s = repl.Replace(s)

	var b strings.Builder
	for _, r := range s {
		switch {
		case r >= '0' && r <= '9':
			b.WriteRune(r)
		case r >= '๐' && r <= '๙':
			b.WriteRune(r - '๐' + '0')
		case r >= '０' && r <= '９':
			b.WriteRune(r - '０' + '0')
		}
	}
	return b.String()
}

func ThaiIDChecksumOK(id13 string) bool {
	if len(id13) != 13 {
		return false
	}
	sum := 0
	for i := 0; i < 12; i++ {
		sum += int(id13[i]-'0') * (13 - i)
	}
	check := (11 - (sum % 11)) % 10
	return check == int(id13[12]-'0')
}

func pickBestThaiID(digits string, requireChecksum bool) string {
	if len(digits) < 13 {
		return ""
	}
	best := ""
	for i := 0; i+13 <= len(digits); i++ {
		cand := digits[i : i+13]
		if requireChecksum {
			if ThaiIDChecksumOK(cand) {
				return cand
			}
		} else {
			if best == "" {
				best = cand
			}
		}
	}
	return best
}
