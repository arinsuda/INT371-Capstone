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

	eff := s.effectiveParamsForID(req)

	if eff.timeoutSec > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, time.Duration(eff.timeoutSec)*time.Second)
		defer cancel()
	}

	execResult, err := s.strategyManager.Execute(ctx, imageData, eff.language)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to execute strategies: %w", err)
	}
	if execResult == nil {
		return nil, nil, errors.New("strategy execution returned nil result")
	}

	if execResult.BestResult == nil {
		return s.createFailedIDResponse(execResult), s.createMetadata(execResult, start), nil
	}

	if eff.stopOnSuccess && execResult.BestResult.Confidence >= eff.minConfidenceStop {
		// proceed
	}

	// ✅ ปรับปรุง: ลองดึงเลขบัตรด้วย validator ที่ปรับปรุงแล้ว
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
		// ✅ Fallback ที่ปรับปรุงแล้ว: ใช้ validator ที่มี aggressive normalization
		if eff.allowFallback {
			// validator จะจัดการ normalization เองแล้ว
			warnings = append(warnings, fmt.Sprintf("Using fallback extraction (original error: %v)", idErr))
		} else {
			warnings = append(warnings, "No valid ID card number detected")
		}
	}

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
	lang := strings.TrimSpace(req.Language)
	if lang == "" {
		if s.config != nil && strings.TrimSpace(s.config.Language) != "" {
			lang = s.config.Language
		} else {
			lang = "eng"
		}
	}

	cMin := req.MinConfidence
	if cMin <= 0 && s.config != nil && s.config.ConfidenceMin > 0 {
		cMin = s.config.ConfidenceMin
	}
	if cMin <= 0 {
		cMin = 0.20
	}

	sos := req.StopOnSuccess
	if s.config != nil && !sos {
		if s.config.StopOnSuccess {
			sos = true
		} else if s.config.Strategies.StopOnFirstSuccess {
			sos = true
		}
	}

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

	valChecksum := req.ValidateChecksum
	if s.config != nil {
		if !valChecksum && s.config.IDCard.ValidateChecksum {
			valChecksum = true
		}
		if !valChecksum && s.config.ValidateChecksum {
			valChecksum = true
		}
	}

	allowFallback := true
	if s.config != nil {
		allowFallback = s.config.AllowFallback
		if !s.config.AllowFallback {
			allowFallback = true
		}
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

// ✅ ลบฟังก์ชัน CleanToAsciiDigits, ThaiIDChecksumOK, pickBestThaiID
// เพราะย้ายไปอยู่ใน validator แล้ว