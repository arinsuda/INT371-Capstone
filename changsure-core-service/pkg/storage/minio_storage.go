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

var (
	ErrEmptyKey = errors.New("storage: key cannot be empty")
)

type MinioStorage struct {
	client     *minio.Client
	bucket     string
	cfg        *config.MinioConfig
	publicBase *url.URL
}

var GlobalMinio *MinioStorage

// ======================================================
// Constructor
// ======================================================

func NewMinioFromConfig(cfg config.MinioConfig) (*MinioStorage, error) {
	if cfg.Endpoint == "" {
		return nil, errors.New("minio endpoint required")
	}
	if cfg.AccessKey == "" || cfg.SecretKey == "" {
		return nil, errors.New("minio credentials required")
	}
	if cfg.Bucket == "" {
		return nil, errors.New("minio bucket required")
	}

	client, err := minio.New(cfg.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
		Secure: cfg.UseSSL,
		Region: cfg.Region,
	})
	if err != nil {
		return nil, fmt.Errorf("minio client init: %w", err)
	}

	var publicBase *url.URL
	if cfg.PublicBaseURL != "" {
		publicBase, err = url.Parse(cfg.PublicBaseURL)
		if err != nil {
			return nil, fmt.Errorf("invalid public base url: %w", err)
		}
	}

	s := &MinioStorage{
		client:     client,
		bucket:     cfg.Bucket,
		cfg:        &cfg,
		publicBase: publicBase,
	}

	// Ensure bucket
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	exists, err := s.client.BucketExists(ctx, cfg.Bucket)
	if err != nil {
		return nil, fmt.Errorf("check bucket: %w", err)
	}
	if !exists {
		if err := s.client.MakeBucket(ctx, cfg.Bucket, minio.MakeBucketOptions{}); err != nil {
			return nil, fmt.Errorf("make bucket: %w", err)
		}
	}

	return s, nil
}

// ======================================================
// Utility
// ======================================================

// sanitize key to avoid "//" and root traversal
func sanitizeKey(key string) string {
	return strings.TrimPrefix(path.Clean("/"+key), "/")
}

// Convert MinIO internal presigned URL to public URL
// - changes ONLY host (and scheme if provided)
// - keeps path + query AS-IS
func (s *MinioStorage) toPublicURL(raw string) string {
	public := s.cfg.PublicBaseURL
	if public == "" {
		return raw
	}

	u, err := url.Parse(raw)
	if err != nil {
		return raw
	}

	p, _ := url.Parse(public)
	if p.Scheme == "" {
		p.Scheme = "http"
	}

	// Only replace host:port
	u.Host = p.Host
	u.Scheme = p.Scheme

	return u.String()
}

// ======================================================
// Upload
// ======================================================

func (s *MinioStorage) Put(ctx context.Context, key string, r io.Reader, size int64, contentType string) error {
	if key == "" {
		return ErrEmptyKey
	}

	key = sanitizeKey(key)

	_, err := s.client.PutObject(ctx, s.bucket, key, r, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return fmt.Errorf("put object %q: %w", key, err)
	}

	return nil
}

// ======================================================
// Presigned PUT
// ======================================================

func (s *MinioStorage) PresignPut(ctx context.Context, key, contentType string, ttl time.Duration) (string, error) {
	if key == "" {
		return "", ErrEmptyKey
	}

	key = sanitizeKey(key)

	u, err := s.client.PresignedPutObject(ctx, s.bucket, key, ttl)
	if err != nil {
		return "", fmt.Errorf("presigned put: %w", err)
	}

	return s.toPublicURL(u.String()), nil
}

// ======================================================
// Presigned GET (with optional attachment)
// ======================================================

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
		return "", fmt.Errorf("presigned get: %w", err)
	}

	return s.toPublicURL(u.String()), nil
}

// GET with filename
func (s *MinioStorage) PresignGetWithFilename(ctx context.Context, key string, ttl time.Duration, filename string) (string, error) {
	if key == "" {
		return "", ErrEmptyKey
	}
	key = sanitizeKey(key)

	params := url.Values{}
	if filename != "" {
		params.Set("response-content-disposition",
			fmt.Sprintf(`attachment; filename="%s"`, strings.ReplaceAll(filename, `"`, `\"`)))
	}

	u, err := s.client.PresignedGetObject(ctx, s.bucket, key, ttl, params)
	if err != nil {
		return "", fmt.Errorf("presigned get filename: %w", err)
	}

	return s.toPublicURL(u.String()), nil
}

// ======================================================
// Presigned POST
// ======================================================

func (s *MinioStorage) PresignPost(ctx context.Context, key, contentType string, maxBytes int64, ttl time.Duration) (*url.URL, map[string]string, error) {
	if key == "" {
		return nil, nil, ErrEmptyKey
	}

	key = sanitizeKey(key)

	p := minio.NewPostPolicy()

	p.SetBucket(s.bucket)
	p.SetKey(key)
	p.SetExpires(time.Now().UTC().Add(ttl))

	if contentType != "" {
		p.SetContentType(contentType)
	}
	if maxBytes > 0 {
		p.SetContentLengthRange(1, maxBytes)
	}

	u, form, err := s.client.PresignedPostPolicy(ctx, p)
	if err != nil {
		return nil, nil, fmt.Errorf("presigned post: %w", err)
	}

	public := s.toPublicURL(u.String())
	outURL, err := url.Parse(public)
	if err != nil {
		return nil, nil, fmt.Errorf("invalid public url: %w", err)
	}

	return outURL, form, nil
}

// ======================================================
// Stat
// ======================================================

func (s *MinioStorage) Stat(ctx context.Context, key string) (*ObjectStat, error) {
	if key == "" {
		return nil, ErrEmptyKey
	}

	key = sanitizeKey(key)

	st, err := s.client.StatObject(ctx, s.bucket, key, minio.StatObjectOptions{})
	if err != nil {
		return nil, fmt.Errorf("stat %q: %w", key, err)
	}

	return &ObjectStat{
		Size:     st.Size,
		ETag:     st.ETag,
		MIMEType: st.ContentType,
	}, nil
}

// ======================================================
// Delete
// ======================================================

func (s *MinioStorage) Delete(ctx context.Context, key string) error {
	if key == "" {
		return ErrEmptyKey
	}

	key = sanitizeKey(key)

	err := s.client.RemoveObject(ctx, s.bucket, key, minio.RemoveObjectOptions{})
	if err != nil {
		return fmt.Errorf("delete %q: %w", key, err)
	}

	return nil
}

// ======================================================
// UploadFile
// ======================================================

func (s *MinioStorage) UploadFile(ctx context.Context, r io.Reader, filename, folder string, size int64, contentType string) (string, error) {
	if filename == "" {
		return "", errors.New("filename required")
	}

	if folder != "" {
		folder = strings.Trim(folder, "/") + "/"
	}

	key := fmt.Sprintf("%s%d-%s", folder, time.Now().UnixNano(), filename)

	if err := s.Put(ctx, key, r, size, contentType); err != nil {
		return "", err
	}

	return key, nil
}

// ======================================================
// Direct Public URL (non-presigned)
// ======================================================

func (s *MinioStorage) PublicURL(key string) string {
	if key == "" {
		return ""
	}

	key = sanitizeKey(key)

	u := url.URL{
		Scheme: "http",
		Host:   s.cfg.Endpoint,
		Path:   fmt.Sprintf("/%s/%s", s.bucket, key),
	}

	if s.cfg.UseSSL {
		u.Scheme = "https"
	}

	return s.toPublicURL(u.String())
}

func (s *MinioStorage) Config() *config.MinioConfig {
	return s.cfg
}
