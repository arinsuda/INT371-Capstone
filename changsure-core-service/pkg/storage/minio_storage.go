package storage

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/url"
	"path"
	"strings"
	"time"

	"changsure-core-service/internal/config"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// Common errors
var (
	ErrEmptyKey        = errors.New("storage: empty key provided")
	ErrInvalidURL      = errors.New("storage: invalid URL")
	ErrBucketOperation = errors.New("storage: bucket operation failed")
)

// ObjectStat represents object metadata
type ObjectStat struct {
	Size     int64
	ETag     string
	MIMEType string
}

// Storage defines the interface for object storage operations
type Storage interface {
	Put(ctx context.Context, key string, r io.Reader, size int64, contentType string) error
	PresignPut(ctx context.Context, key, contentType string, ttl time.Duration) (string, error)
	PresignGet(ctx context.Context, key string, ttl time.Duration, asAttachment bool) (string, error)
	PresignGetWithFilename(ctx context.Context, key string, ttl time.Duration, filename string) (string, error)
	Stat(ctx context.Context, key string) (*ObjectStat, error)
	Delete(ctx context.Context, key string) error
	UploadFile(ctx context.Context, r io.Reader, filename, folder string, size int64, contentType string) (string, error)
	PublicURL(key string) string
}

// MinioStorage implements Storage interface for MinIO
type MinioStorage struct {
	client       *minio.Client
	bucket       string
	cfg          *config.MinioConfig
	internalBase string
	publicBase   string
}

// Global instance (consider using dependency injection instead)
var GlobalMinio *MinioStorage

// NewMinioFromConfig creates a new MinIO storage instance
func NewMinioFromConfig(cfg config.MinioConfig) (*MinioStorage, error) {
	if err := validateConfig(&cfg); err != nil {
		return nil, fmt.Errorf("invalid config: %w", err)
	}

	client, err := minio.New(cfg.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
		Secure: cfg.UseSSL,
		Region: cfg.Region,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create minio client: %w", err)
	}

	s := &MinioStorage{
		client:       client,
		bucket:       cfg.Bucket,
		cfg:          &cfg,
		internalBase: buildInternalBaseURL(cfg.Endpoint, cfg.Bucket, cfg.UseSSL),
		publicBase:   strings.TrimRight(cfg.PublicBaseURL, "/"),
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := s.ensureBucketExists(ctx); err != nil {
		return nil, fmt.Errorf("bucket initialization failed: %w", err)
	}

	return s, nil
}

// validateConfig validates MinIO configuration
func validateConfig(cfg *config.MinioConfig) error {
	if cfg.Endpoint == "" {
		return errors.New("endpoint is required")
	}
	if cfg.Bucket == "" {
		return errors.New("bucket is required")
	}
	if cfg.AccessKey == "" || cfg.SecretKey == "" {
		return errors.New("access key and secret key are required")
	}
	return nil
}

// buildInternalBaseURL constructs the internal base URL
func buildInternalBaseURL(endpoint, bucket string, useSSL bool) string {
	scheme := "http"
	if useSSL {
		scheme = "https"
	}
	return fmt.Sprintf("%s://%s/%s", scheme, endpoint, bucket)
}

// ensureBucketExists checks and creates bucket if needed
func (s *MinioStorage) ensureBucketExists(ctx context.Context) error {
	exists, err := s.client.BucketExists(ctx, s.bucket)
	if err != nil {
		return fmt.Errorf("%w: check failed: %v", ErrBucketOperation, err)
	}

	if !exists {
		opts := minio.MakeBucketOptions{
			Region: s.cfg.Region,
		}
		if err := s.client.MakeBucket(ctx, s.bucket, opts); err != nil {
			return fmt.Errorf("%w: create failed: %v", ErrBucketOperation, err)
		}
	}

	return nil
}

// toPublicURL converts internal MinIO URL to public URL
func (s *MinioStorage) toPublicURL(rawURL string) string {
	if s.publicBase == "" {
		return rawURL
	}
	return strings.Replace(rawURL, s.internalBase, s.publicBase, 1)
}

// sanitizeKey normalizes the object key
func sanitizeKey(key string) string {
	return strings.TrimPrefix(path.Clean(key), "/")
}

// Put uploads an object to storage
func (s *MinioStorage) Put(ctx context.Context, key string, r io.Reader, size int64, contentType string) error {
	if key == "" {
		return ErrEmptyKey
	}

	key = sanitizeKey(key)

	opts := minio.PutObjectOptions{
		ContentType: contentType,
	}

	_, err := s.client.PutObject(ctx, s.bucket, key, r, size, opts)
	if err != nil {
		return fmt.Errorf("failed to put object %q: %w", key, err)
	}

	return nil
}

// PresignPut generates a presigned URL for uploading
func (s *MinioStorage) PresignPut(ctx context.Context, key, contentType string, ttl time.Duration) (string, error) {
	if key == "" {
		return "", ErrEmptyKey
	}

	key = sanitizeKey(key)

	u, err := s.client.PresignedPutObject(ctx, s.bucket, key, ttl)
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned PUT URL: %w", err)
	}

	return s.toPublicURL(u.String()), nil
}

// PresignGet generates a presigned URL for downloading
func (s *MinioStorage) PresignGet(ctx context.Context, key string, ttl time.Duration, asAttachment bool) (string, error) {
	if key == "" {
		return "", ErrEmptyKey
	}

	key = sanitizeKey(key)

	params := url.Values{}
	if asAttachment {
		params.Set("response-content-disposition", "attachment")
	}

	u, err := s.client.PresignedGetObject(ctx, s.bucket, key, ttl, params)
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned GET URL: %w", err)
	}

	return s.toPublicURL(u.String()), nil
}

// PresignGetWithFilename generates a presigned URL with custom filename
func (s *MinioStorage) PresignGetWithFilename(ctx context.Context, key string, ttl time.Duration, filename string) (string, error) {
	if key == "" {
		return "", ErrEmptyKey
	}

	key = sanitizeKey(key)

	params := url.Values{}
	if filename != "" {
		// Properly escape filename for Content-Disposition header
		disposition := fmt.Sprintf(`attachment; filename="%s"`, escapeQuotes(filename))
		params.Set("response-content-disposition", disposition)
	}

	u, err := s.client.PresignedGetObject(ctx, s.bucket, key, ttl, params)
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned GET URL with filename: %w", err)
	}

	return s.toPublicURL(u.String()), nil
}

// escapeQuotes escapes double quotes in filename
func escapeQuotes(s string) string {
	return strings.ReplaceAll(s, `"`, `\"`)
}

// PresignPost generates presigned POST policy
func (s *MinioStorage) PresignPost(ctx context.Context, key, contentType string, maxBytes int64, ttl time.Duration) (*url.URL, map[string]string, error) {
	if key == "" {
		return nil, nil, ErrEmptyKey
	}

	key = sanitizeKey(key)

	policy := minio.NewPostPolicy()
	if err := policy.SetBucket(s.bucket); err != nil {
		return nil, nil, fmt.Errorf("failed to set bucket in policy: %w", err)
	}
	if err := policy.SetKey(key); err != nil {
		return nil, nil, fmt.Errorf("failed to set key in policy: %w", err)
	}
	if err := policy.SetExpires(time.Now().UTC().Add(ttl)); err != nil {
		return nil, nil, fmt.Errorf("failed to set expiry in policy: %w", err)
	}

	if contentType != "" {
		_ = policy.SetContentType(contentType)
	}
	if maxBytes > 0 {
		_ = policy.SetContentLengthRange(1, maxBytes)
	}

	u, formData, err := s.client.PresignedPostPolicy(ctx, policy)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to generate presigned POST policy: %w", err)
	}

	publicURL, err := url.Parse(s.toPublicURL(u.String()))
	if err != nil {
		return nil, nil, fmt.Errorf("%w: %v", ErrInvalidURL, err)
	}

	return publicURL, formData, nil
}

// Stat retrieves object metadata
func (s *MinioStorage) Stat(ctx context.Context, key string) (*ObjectStat, error) {
	if key == "" {
		return nil, ErrEmptyKey
	}

	key = sanitizeKey(key)

	info, err := s.client.StatObject(ctx, s.bucket, key, minio.StatObjectOptions{})
	if err != nil {
		return nil, fmt.Errorf("failed to stat object %q: %w", key, err)
	}

	return &ObjectStat{
		Size:     info.Size,
		ETag:     info.ETag,
		MIMEType: info.ContentType,
	}, nil
}

// Delete removes an object from storage
func (s *MinioStorage) Delete(ctx context.Context, key string) error {
	if key == "" {
		return ErrEmptyKey
	}

	key = sanitizeKey(key)

	opts := minio.RemoveObjectOptions{}
	if err := s.client.RemoveObject(ctx, s.bucket, key, opts); err != nil {
		return fmt.Errorf("failed to delete object %q: %w", key, err)
	}

	return nil
}

// UploadFile uploads a file with automatic key generation
func (s *MinioStorage) UploadFile(ctx context.Context, r io.Reader, filename, folder string, size int64, contentType string) (string, error) {
	if filename == "" {
		return "", errors.New("filename is required")
	}

	// Normalize folder path
	if folder != "" {
		folder = strings.Trim(folder, "/") + "/"
	}

	// Generate unique key with timestamp
	key := fmt.Sprintf("%s%d-%s", folder, time.Now().UnixNano(), filename)

	if err := s.Put(ctx, key, r, size, contentType); err != nil {
		return "", fmt.Errorf("upload failed: %w", err)
	}

	return key, nil
}

// GetPresignedURL is a convenience method for generating presigned GET URLs
// Deprecated: Use PresignGet instead
func (s *MinioStorage) GetPresignedURL(key string) string {
	if key == "" {
		return ""
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	url, err := s.PresignGet(ctx, key, time.Hour, false)
	if err != nil {
		return ""
	}

	return url
}

// PublicURL constructs a public URL for the given key
func (s *MinioStorage) PublicURL(key string) string {
	if key == "" {
		return ""
	}

	// If already a full URL, return as-is
	if strings.HasPrefix(key, "http://") || strings.HasPrefix(key, "https://") {
		return key
	}

	key = sanitizeKey(key)

	scheme := "http"
	if s.cfg.UseSSL {
		scheme = "https"
	}

	rawURL := fmt.Sprintf("%s://%s/%s/%s", scheme, s.cfg.Endpoint, s.bucket, key)

	return s.toPublicURL(rawURL)
}

// Config returns the MinIO configuration
func (s *MinioStorage) Config() *config.MinioConfig {
	return s.cfg
}