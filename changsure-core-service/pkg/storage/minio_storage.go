package storage

import (
	"context"
	"fmt"
	"io"
	"net/url"
	"time"

	"changsure-core-service/internal/config"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// =============================
//  Struct & Globals
// =============================

type MinioStorage struct {
	c      *minio.Client
	bucket string
	cfg    *config.MinioConfig
}

var GlobalMinio *MinioStorage

// =============================
//  Initialization
// =============================

func MustInit(c config.MinioConfig) {
	s, err := NewMinioFromConfig(c)
	if err != nil {
		panic("MinIO failed to start: " + err.Error())
	}
	GlobalMinio = s
}

func NewMinioStorage(opt MinioOptions) (*MinioStorage, error) {
	client, err := minio.New(opt.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(opt.AccessKey, opt.SecretKey, ""),
		Secure: opt.UseSSL,
		Region: opt.Region,
	})
	if err != nil {
		return nil, fmt.Errorf("minio new client: %w", err)
	}

	s := &MinioStorage{c: client, bucket: opt.Bucket}

	if err := s.ensureBucket(context.Background()); err != nil {
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

// =============================
//  Bucket Handling
// =============================

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

// =============================
//  Raw Put
// =============================

func (s *MinioStorage) Put(
	ctx context.Context,
	key string,
	r io.Reader,
	size int64,
	contentType string,
) (minio.UploadInfo, error) {

	info, err := s.c.PutObject(ctx, s.bucket, key, r, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return minio.UploadInfo{}, fmt.Errorf("put object: %w", err)
	}
	return info, nil
}

// =============================
//  Presigned URLs
// =============================

func (s *MinioStorage) PresignGet(
	ctx context.Context,
	key string,
	ttl time.Duration,
	asAttachment bool,
) (string, error) {

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

func (s *MinioStorage) PresignGetWithFilename(
	ctx context.Context,
	key string,
	ttl time.Duration,
	filename string,
) (string, error) {

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

func (s *MinioStorage) PresignPut(
	ctx context.Context,
	key, contentType string,
	ttl time.Duration,
) (string, error) {

	u, err := s.c.PresignedPutObject(ctx, s.bucket, key, ttl)
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

// =============================
//  Upload File (Best Practice)
// =============================


func (s *MinioStorage) UploadFile(
	ctx context.Context,
	r io.Reader,
	filename, folder string,
	size int64,
	contentType string,
) (string, error) {

	key := filename
	if folder != "" {
		key = folder + "/" + filename
	}

	_, err := s.Put(ctx, key, r, size, contentType)
	if err != nil {
		return "", err
	}

	// Only return object key
	return key, nil
}

// =============================
//  Helpers
// =============================

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

func (s *MinioStorage) Config() *config.MinioConfig {
	return s.cfg
}
