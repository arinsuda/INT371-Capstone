package service

import "changsure-core-service/internal/modules/ocr/infra"

type OCRService interface {
	ProcessOCR(imageBytes []byte, filename string) (*infra.OCRResult, error)
}

type ocrService struct {
	client infra.OCRClient
}

func NewOCRService(client infra.OCRClient) OCRService {
	return &ocrService{client: client}
}

func (s *ocrService) ProcessOCR(imageBytes []byte, filename string) (*infra.OCRResult, error) {
	return s.client.Scan(imageBytes, filename)
}
