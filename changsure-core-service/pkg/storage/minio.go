package storage

import (
	"context"
	"net/url"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type MinioOptions struct {
	Endpoint  string
	AccessKey string
	SecretKey string
	UseSSL    bool
	Region    string
	Bucket    string
}

type MinioStorage struct {
	c      *minio.Client
	bucket string
}

func NewMinioStorage(opt MinioOptions) (*MinioStorage, error) {
	c, err := minio.New(opt.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(opt.AccessKey, opt.SecretKey, ""),
		Secure: opt.UseSSL,
		Region: opt.Region,
	})
	if err != nil {
		return nil, err
	}
	return &MinioStorage{c: c, bucket: opt.Bucket}, nil
}

func (s *MinioStorage) PresignPut(ctx context.Context, key, contentType string, ttl time.Duration) (string, error) {
	u, err := s.c.PresignedPutObject(ctx, s.bucket, key, ttl)
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

func (s *MinioStorage) PresignGet(ctx context.Context, key string, ttl time.Duration, asAttachment bool) (string, error) {
	q := url.Values{}
	if asAttachment {
		q.Set("response-content-disposition", "attachment")
	}
	u, err := s.c.PresignedGetObject(ctx, s.bucket, key, ttl, q)
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

func (s *MinioStorage) Stat(ctx context.Context, key string) (*ObjectStat, error) {
	st, err := s.c.StatObject(ctx, s.bucket, key, minio.StatObjectOptions{})
	if err != nil {
		return nil, err
	}
	return &ObjectStat{Size: st.Size, ETag: st.ETag, MIMEType: st.ContentType}, nil
}

func (s *MinioStorage) Delete(ctx context.Context, key string) error {
	return s.c.RemoveObject(ctx, s.bucket, key, minio.RemoveObjectOptions{})
}
