package storage

import (
	"context"
	"fmt"
	"io"
	"net/url"
	"time"
	"net/http"
	"net"

	"changsure-core-service/internal/config"

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
	cfg    *config.MinioConfig
}

func NewMinioStorage(opt MinioOptions) (*MinioStorage, error) {
	transport := &http.Transport{
		DialContext: (&net.Dialer{
			Timeout:   3 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		TLSHandshakeTimeout:   3 * time.Second,
		ResponseHeaderTimeout: 3 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
		IdleConnTimeout:       30 * time.Second,
		MaxIdleConnsPerHost:   10,
	}

	c, err := minio.New(opt.Endpoint, &minio.Options{
		Creds:     credentials.NewStaticV4(opt.AccessKey, opt.SecretKey, ""),
		Secure:    opt.UseSSL,
		Region:    opt.Region,
		Transport: transport,
	})
	if err != nil {
		return nil, fmt.Errorf("minio new client: %w", err)
	}

	s := &MinioStorage{c: c, bucket: opt.Bucket}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	if err := s.ensureBucket(ctx); err != nil {
		return nil, err
	}

	return s, nil
}
func NewMinioFromConfig(c config.MinioConfig) (*MinioStorage, error) {
	s, err := NewMinioStorage(MinioOptions{
		Endpoint:  c.Endpoint,
		AccessKey: c.AccessKey,
		SecretKey: c.SecretKey,
		UseSSL:    c.UseSSL,
		Region:    c.Region,
		Bucket:    c.Bucket,
	})
	if err != nil {
		return nil, err
	}
	s.cfg = &c
	return s, nil
}

func (s *MinioStorage) ensureBucket(ctx context.Context) error {
	exists, err := s.c.BucketExists(ctx, s.bucket)
	if err != nil {
		return fmt.Errorf("check bucket: %w", err)
	}
	if !exists {
		if err := s.c.MakeBucket(ctx, s.bucket, minio.MakeBucketOptions{}); err != nil {
			return fmt.Errorf("make bucket: %w", err)
		}
	}
	return nil
}

func (s *MinioStorage) Put(ctx context.Context, key string, r io.Reader, size int64, contentType string) (minio.UploadInfo, error) {
	info, err := s.c.PutObject(ctx, s.bucket, key, r, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return minio.UploadInfo{}, fmt.Errorf("put object: %w", err)
	}
	return info, nil
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

func (s *MinioStorage) PresignGetWithFilename(ctx context.Context, key string, ttl time.Duration, filename string) (string, error) {
	q := url.Values{}
	if filename != "" {
		q.Set("response-content-disposition", `attachment; filename="`+filename+`"`)
	}
	u, err := s.c.PresignedGetObject(ctx, s.bucket, key, ttl, q)
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

func (s *MinioStorage) PresignPost(ctx context.Context, key string, contentType string, maxBytes int64, ttl time.Duration) (*url.URL, map[string]string, error) {
	policy := minio.NewPostPolicy()
	if err := policy.SetBucket(s.bucket); err != nil {
		return nil, nil, err
	}
	if err := policy.SetKey(key); err != nil {
		return nil, nil, err
	}
	if contentType != "" {
		if err := policy.SetContentType(contentType); err != nil {
			return nil, nil, err
		}
	}
	if maxBytes > 0 {
		if err := policy.SetContentLengthRange(1, maxBytes); err != nil {
			return nil, nil, err
		}
	}
	if err := policy.SetExpires(time.Now().UTC().Add(ttl)); err != nil {
		return nil, nil, err
	}

	u, formData, err := s.c.PresignedPostPolicy(ctx, policy)
	if err != nil {
		return nil, nil, err
	}
	return u, formData, nil
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
