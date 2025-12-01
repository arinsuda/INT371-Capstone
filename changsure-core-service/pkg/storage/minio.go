package storage

import (
	"context"
	"fmt"
	"io"
	"net/url"
	"strings"
	"time"

	"changsure-core-service/internal/config"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

var GlobalMinio *MinioStorage

// ==============================
// Constructor
// ==============================

func NewMinioFromConfig(cfg config.MinioConfig) (*MinioStorage, error) {
	client, err := minio.New(cfg.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
		Secure: cfg.UseSSL,
		Region: cfg.Region,
	})
	if err != nil {
		return nil, fmt.Errorf("minio new client: %w", err)
	}

	s := &MinioStorage{
		client: client,
		bucket: cfg.Bucket,
		cfg:    &cfg,
	}

	if err := s.ensureBucketExists(context.Background()); err != nil {
		return nil, err
	}

	return s, nil
}

// ==============================
// Bucket Ensure
// ==============================

func (s *MinioStorage) ensureBucketExists(ctx context.Context) error {
	exists, err := s.client.BucketExists(ctx, s.bucket)
	if err != nil {
		return fmt.Errorf("check bucket: %w", err)
	}
	if !exists {
		if err := s.client.MakeBucket(ctx, s.bucket, minio.MakeBucketOptions{}); err != nil {
			return fmt.Errorf("make bucket: %w", err)
		}
	}
	return nil
}

// ==============================
// Helpers
// ==============================

func (s *MinioStorage) internalBaseURL() string {
	return fmt.Sprintf("http://%s/%s", s.cfg.Endpoint, s.cfg.Bucket)
}

func (s *MinioStorage) publicBaseURL() string {
	if s.cfg.PublicBaseURL == "" {
		return ""
	}
	return strings.TrimRight(s.cfg.PublicBaseURL, "/")
}

// Convert internal MinIO URL → Public URL
func (s *MinioStorage) toPublicURL(raw string) string {
	public := s.publicBaseURL()
	if public == "" {
		return raw
	}

	internal := s.internalBaseURL()
	return strings.Replace(raw, internal, public, 1)
}

// ==============================
// PUT
// ==============================

func (s *MinioStorage) Put(ctx context.Context, key string, r io.Reader, size int64, contentType string) (minio.UploadInfo, error) {
	info, err := s.client.PutObject(ctx, s.bucket, key, r, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return minio.UploadInfo{}, fmt.Errorf("put object: %w", err)
	}
	return info, nil
}

// ==============================
// Presigned PUT
// ==============================

func (s *MinioStorage) PresignPut(ctx context.Context, key, contentType string, ttl time.Duration) (string, error) {
	u, err := s.client.PresignedPutObject(ctx, s.bucket, key, ttl)
	if err != nil {
		return "", err
	}
	return s.toPublicURL(u.String()), nil
}

// ==============================
// Presigned GET (Normal Download)
// ==============================

func (s *MinioStorage) PresignGet(ctx context.Context, key string, ttl time.Duration, asAttachment bool) (string, error) {
	q := url.Values{}
	if asAttachment {
		q.Set("response-content-disposition", "attachment")
	}

	u, err := s.client.PresignedGetObject(ctx, s.bucket, key, ttl, q)
	if err != nil {
		return "", err
	}

	return s.toPublicURL(u.String()), nil
}

// ==============================
// Presigned GET with Filename
// ==============================

func (s *MinioStorage) PresignGetWithFilename(ctx context.Context, key string, ttl time.Duration, filename string) (string, error) {
	q := url.Values{}
	if filename != "" {
		q.Set("response-content-disposition", `attachment; filename="`+filename+`"`)
	}

	u, err := s.client.PresignedGetObject(ctx, s.bucket, key, ttl, q)
	if err != nil {
		return "", err
	}

	return s.toPublicURL(u.String()), nil
}

// ==============================
// Presigned POST Upload Policy
// ==============================

func (s *MinioStorage) PresignPost(ctx context.Context, key, contentType string, maxBytes int64, ttl time.Duration) (*url.URL, map[string]string, error) {
	policy := minio.NewPostPolicy()
	policy.SetBucket(s.bucket)
	policy.SetKey(key)
	policy.SetExpires(time.Now().UTC().Add(ttl))

	if contentType != "" {
		_ = policy.SetContentType(contentType)
	}
	if maxBytes > 0 {
		_ = policy.SetContentLengthRange(1, maxBytes)
	}

	u, formData, err := s.client.PresignedPostPolicy(ctx, policy)
	if err != nil {
		return nil, nil, err
	}

	// Convert host to public
	publicURL, _ := url.Parse(s.toPublicURL(u.String()))
	return publicURL, formData, nil
}

// ==============================
// Stat
// ==============================

type ObjectStat struct {
	Size     int64
	ETag     string
	MIMEType string
}

func (s *MinioStorage) Stat(ctx context.Context, key string) (*ObjectStat, error) {
	st, err := s.client.StatObject(ctx, s.bucket, key, minio.StatObjectOptions{})
	if err != nil {
		return nil, err
	}
	return &ObjectStat{
		Size:     st.Size,
		ETag:     st.ETag,
		MIMEType: st.ContentType,
	}, nil
}

// ==============================
// Delete
// ==============================

func (s *MinioStorage) Delete(ctx context.Context, key string) error {
	return s.client.RemoveObject(ctx, s.bucket, key, minio.RemoveObjectOptions{})
}

// ==============================
// UploadFile
// ==============================

func (s *MinioStorage) UploadFile(ctx context.Context, r io.Reader, filename, folder string, size int64, contentType string) (string, error) {
	if folder != "" && !strings.HasSuffix(folder, "/") {
		folder += "/"
	}

	key := fmt.Sprintf("%s%d-%s", folder, time.Now().UnixNano(), filename)

	_, err := s.Put(ctx, key, r, size, contentType)
	if err != nil {
		return "", err
	}

	return key, nil
}

// ==============================
// Direct Presigned URL (shortcut)
// ==============================

func (s *MinioStorage) GetPresignedURL(key string) string {
	if key == "" {
		return ""
	}

	raw, err := s.PresignGet(context.Background(), key, time.Hour, false)
	if err != nil {
		return ""
	}

	return raw
}

// ==============================
// Config Access
// ==============================

func (s *MinioStorage) Config() *config.MinioConfig {
	return s.cfg
}
