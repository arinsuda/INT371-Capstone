package worker

import (
	"context"
	"log"
)

type Pool struct {
	ocrWorker *OCRWorker
}

func NewPool(ocr *OCRWorker) *Pool {
	return &Pool{ocrWorker: ocr}
}

func (p *Pool) Start(ctx context.Context) {
	log.Println("🚀 Worker Pool: starting all workers")

	go p.ocrWorker.Start(ctx)

	<-ctx.Done()
	log.Println("🛑 Worker Pool: all workers stopped")
}
