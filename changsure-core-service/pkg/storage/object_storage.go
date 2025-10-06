package storage

import (
	"context"
	"time"
)

type ObjectStat struct {
	Size     int64
	ETag     string
	MIMEType string
}

type ObjectStorage interface {
	PresignPut(ctx context.Context, key, contentType string, ttl time.Duration) (string, error)
	PresignGet(ctx context.Context, key string, ttl time.Duration, asAttachment bool) (string, error)
	Stat(ctx context.Context, key string) (*ObjectStat, error)
	Delete(ctx context.Context, key string) error
}
