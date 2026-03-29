package service

import "changsure-core-service/internal/modules/ocr/infra"

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
	return s.client.Scan(imageBytes, filename)
}

func (s *ocrService) Ping() (*infra.OCRHealth, error) {
	return s.client.Health()
}