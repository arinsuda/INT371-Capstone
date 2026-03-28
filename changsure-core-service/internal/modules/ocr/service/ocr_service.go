package service

import (
	"changsure-core-service/internal/modules/ocr/infra"
	"fmt"
	"time"
)

type OCRService interface {
	ProcessOCR(imageBytes []byte, filename string) (*infra.OCRResult, error)
	Ping() (*infra.OCRHealth, error)
}

type ocrService struct {
	client infra.OCRClient
}

func NewOCRService(client infra.OCRClient) OCRService {
	return &ocrService{client: client}
}

func (s *ocrService) ProcessOCR(imageBytes []byte, filename string) (*infra.OCRResult, error) {
    var lastErr error

    for i := 0; i < 3; i++ {
        res, err := s.client.Scan(imageBytes, filename)
        if err == nil {
            return res, nil
        }

        lastErr = err
        time.Sleep(time.Duration(i+1) * 2 * time.Second)
    }

    return nil, fmt.Errorf("ocr failed after retries: %w", lastErr)
}

func (s *ocrService) Ping() (*infra.OCRHealth, error) {
	return s.client.Health()
}