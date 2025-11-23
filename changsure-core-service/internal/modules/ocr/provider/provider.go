package provider

import (
	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/infra"
	"changsure-core-service/internal/modules/ocr/service"
)

type OCRProvider struct {
	OCRService service.OCRService
}

func NewOCRProvider(cfg config.OCRConfig) *OCRProvider {
	client := infra.NewOCRClient(cfg.BaseURL)
	svc := service.NewOCRService(client)
	return &OCRProvider{
		OCRService: svc,
	}
}
