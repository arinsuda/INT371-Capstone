package service

import (
	"context"
	"fmt"
	"time"

	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/dto"
	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/strategy"
	"changsure-core-service/internal/modules/ocr/validator"
)

// OCRService หลัก (Facade Pattern)
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

// ProcessIDCard ประมวลผลบัตรประชาชน
func (s *OCRService) ProcessIDCard(ctx context.Context, imageData []byte, req *dto.IDCardRequest) (*dto.IDCardData, *dto.Metadata, error) {
	startTime := time.Now()

	// Set defaults
	req.SetDefaults()

	// สร้าง context พร้อม timeout
	if req.Timeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, time.Duration(req.Timeout)*time.Second)
		defer cancel()
	}

	// รัน strategies ผ่าน StrategyManager
	execResult, err := s.strategyManager.Execute(ctx, imageData, req.Language)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to execute strategies: %w", err)
	}

	// ถ้าไม่เจอ result เลย
	if execResult.BestResult == nil {
		return s.createFailedResponse(execResult, startTime), s.createMetadata(execResult, startTime), nil
	}

	// Extract ID number
	idNumber, idErr := s.validator.ExtractIDNumber(execResult.BestResult.Text)
	
	// Validate checksum
	checksumValid := false
	formatValid := false
	warnings := []string{}

	if idErr == nil && idNumber != "" {
		formatValid = true
		if req.ValidateChecksum {
			if err := s.validator.ValidateChecksum(idNumber); err != nil {
				warnings = append(warnings, fmt.Sprintf("Checksum validation failed: %v", err))
			} else {
				checksumValid = true
			}
		} else {
			checksumValid = true // assume valid if not validating
		}
	} else {
		warnings = append(warnings, "No valid ID card number detected")
	}

	// สร้าง response
	idCardData := &dto.IDCardData{
		OCRData: dto.OCRData{
			RawText:    execResult.BestResult.Text,
			Confidence: execResult.BestResult.Confidence,
			Language:   execResult.BestResult.Language,
			IsValid:    checksumValid && formatValid,
			Warnings:   warnings,
		},
		IDNumber:      idNumber,
		ChecksumValid: checksumValid,
		FormatValid:   formatValid,
	}

	// สร้าง metadata
	metadata := s.createMetadata(execResult, startTime)

	return idCardData, metadata, nil
}

// ExtractText ดึงข้อความทั่วไป (ไม่ใช่บัตรประชาชน)
func (s *OCRService) ExtractText(ctx context.Context, imageData []byte, req *dto.OCRRequest) (*dto.OCRData, *dto.Metadata, error) {
	startTime := time.Now()

	// Set defaults
	req.SetDefaults()

	// สร้าง context พร้อม timeout
	if req.Timeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, time.Duration(req.Timeout)*time.Second)
		defer cancel()
	}

	// รัน strategies
	execResult, err := s.strategyManager.Execute(ctx, imageData, req.Language)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to execute strategies: %w", err)
	}

	if execResult.BestResult == nil {
		return &dto.OCRData{
			IsValid:  false,
			Warnings: []string{"No text could be extracted"},
		}, s.createMetadata(execResult, startTime), nil
	}

	warnings := []string{}
	if execResult.BestResult.Confidence < s.config.ConfidenceMin {
		warnings = append(warnings, fmt.Sprintf(
			"OCR confidence (%.2f) is below minimum threshold (%.2f)",
			execResult.BestResult.Confidence,
			s.config.ConfidenceMin,
		))
	}

	ocrData := &dto.OCRData{
		RawText:    execResult.BestResult.Text,
		Confidence: execResult.BestResult.Confidence,
		Language:   execResult.BestResult.Language,
		IsValid:    execResult.BestResult.Confidence >= s.config.ConfidenceMin,
		Warnings:   warnings,
	}

	metadata := s.createMetadata(execResult, startTime)

	return ocrData, metadata, nil
}

// createFailedResponse สร้าง response สำหรับกรณีล้มเหลว
func (s *OCRService) createFailedResponse(execResult *strategy.ExecutionResult, startTime time.Time) *dto.IDCardData {
	warnings := []string{"All strategies failed to extract ID card number"}
	
	// รวบรวม errors จาก strategies
	for _, result := range execResult.StrategyResults {
		if !result.Success && result.Error != nil {
			warnings = append(warnings, fmt.Sprintf("%s: %v", result.Name, result.Error))
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

// createMetadata สร้าง metadata
func (s *OCRService) createMetadata(execResult *strategy.ExecutionResult, startTime time.Time) *dto.Metadata {
	strategyResults := make([]dto.StrategyResult, 0, len(execResult.StrategyResults))
	
	var strategyUsed string
	for _, result := range execResult.StrategyResults {
		strategyResult := dto.StrategyResult{
			Name:           result.Name,
			Success:        result.Success,
			ProcessingTime: result.ProcessingTime.Milliseconds(),
		}

		if result.Success && result.OCRResult != nil {
			strategyResult.Confidence = result.OCRResult.Confidence
			if result.Metadata != nil {
				if idFound, ok := result.Metadata["id_found"].(bool); ok {
					strategyResult.IDFound = idFound
				}
			}
		}

		if result.Error != nil {
			strategyResult.Error = result.Error.Error()
		}

		strategyResults = append(strategyResults, strategyResult)

		// หา strategy ที่ใช้จริง
		if execResult.BestResult != nil && result.Success && result.OCRResult == execResult.BestResult {
			strategyUsed = result.Name
		}
	}

	metadata := &dto.Metadata{
		ProcessingTime:  time.Since(startTime).Milliseconds(),
		StrategyUsed:    strategyUsed,
		TotalStrategies: len(execResult.StrategyResults),
		StrategyResults: strategyResults,
		Version:         "2.0.0",
	}

	return metadata
}

// GetMetrics ดึง metrics
func (s *OCRService) GetMetrics() map[string]interface{} {
	if s.metrics == nil {
		return nil
	}
	return s.metrics.GetMetrics()
}

// Close ปิด service
func (s *OCRService) Close() error {
	// Clean up resources if needed
	return nil
}