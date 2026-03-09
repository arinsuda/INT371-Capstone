package storage

import (
	"context"
	"io"
	"time"

	"github.com/minio/minio-go/v7"
)

type Storage interface {
	Put(ctx context.Context, key string, r io.Reader, size int64, contentType string) (minio.UploadInfo, error)

	PresignPut(ctx context.Context, key, contentType string, ttl time.Duration) (string, error)
	PresignGet(ctx context.Context, key string, ttl time.Duration, asAttachment bool) (string, error)
	PresignGetWithFilename(ctx context.Context, key string, ttl time.Duration, filename string) (string, error)
	Stat(ctx context.Context, key string) (*ObjectStat, error)
	Delete(ctx context.Context, key string) error
	UploadFile(ctx context.Context, r io.Reader, filename, folder string, size int64, contentType string) (string, error)

	Download(ctx context.Context, key string) ([]byte, error)
}
