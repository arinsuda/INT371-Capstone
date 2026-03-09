package storage

import (
	"bytes"
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

type MinioStorage struct {
	internal *minio.Client
	signer   *minio.Client
	bucket   string
	cfg      *config.MinioConfig
}

var GlobalMinio *MinioStorage

func MustInit(c config.MinioConfig) {
	s, err := NewMinioFromConfig(c)
	if err != nil {
		panic("MinIO failed to start: " + err.Error())
	}
	GlobalMinio = s
}

func NewMinioStorage(opt MinioOptions) (*MinioStorage, error) {
	internal, err := minio.New(opt.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(opt.AccessKey, opt.SecretKey, ""),
		Secure: false,
		Region: opt.Region,
	})
	if err != nil {
		return nil, fmt.Errorf("init internal client: %w", err)
	}

	publicHost := opt.PublicBaseURL
	if publicHost == "" {
		publicHost = opt.Endpoint
	}
	publicHost = strings.TrimPrefix(publicHost, "http://")
	publicHost = strings.TrimPrefix(publicHost, "https://")

	signer, err := minio.New(publicHost, &minio.Options{
		Creds:  credentials.NewStaticV4(opt.AccessKey, opt.SecretKey, ""),
		Secure: opt.UseSSL,
		Region: opt.Region,
	})
	if err != nil {
		return nil, fmt.Errorf("init signer client: %w", err)
	}

	s := &MinioStorage{
		internal: internal,
		signer:   signer,
		bucket:   opt.Bucket,
	}

	if err := s.ensureBucket(context.Background()); err != nil {
		return nil, err
	}

	return s, nil
}

func NewMinioFromConfig(c config.MinioConfig) (*MinioStorage, error) {
	internalClient, err := minio.New(c.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(c.AccessKey, c.SecretKey, ""),
		Secure: false,
		Region: c.Region,
	})
	if err != nil {
		return nil, fmt.Errorf("init internal client: %w", err)
	}

	publicHost := c.PublicBaseURL
	if publicHost == "" {
		publicHost = c.Endpoint
	}

	publicHost = strings.TrimPrefix(publicHost, "http://")
	publicHost = strings.TrimPrefix(publicHost, "https://")

	signerClient, err := minio.New(publicHost, &minio.Options{
		Creds:  credentials.NewStaticV4(c.AccessKey, c.SecretKey, ""),
		Secure: c.UseSSL,
		Region: c.Region,
	})
	if err != nil {
		return nil, fmt.Errorf("init signer client: %w", err)
	}

	s := &MinioStorage{
		internal: internalClient,
		signer:   signerClient,
		bucket:   c.Bucket,
		cfg:      &c,
	}

	if err := s.ensureBucket(context.Background()); err != nil {
		return nil, err
	}

	return s, nil
}

func (s *MinioStorage) ensureBucket(ctx context.Context) error {
	exists, err := s.internal.BucketExists(ctx, s.bucket)
	if err != nil {
		return fmt.Errorf("check bucket: %w", err)
	}
	if !exists {
		if err := s.internal.MakeBucket(ctx, s.bucket, minio.MakeBucketOptions{}); err != nil {
			return fmt.Errorf("make bucket: %w", err)
		}
	}
	return nil
}

func (s *MinioStorage) Put(
	ctx context.Context,
	key string,
	r io.Reader,
	size int64,
	contentType string,
) (minio.UploadInfo, error) {

	info, err := s.internal.PutObject(ctx, s.bucket, key, r, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return minio.UploadInfo{}, fmt.Errorf("put object: %w", err)
	}
	return info, nil
}

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

	u, err := s.signer.PresignedGetObject(ctx, s.bucket, key, ttl, q)
	if err != nil {
		return "", err
	}

	signed := u.String()

	if s.cfg.PublicBaseURL != "" {
		base := "https://" + strings.TrimSuffix(s.cfg.PublicBaseURL, "/")

		parsed, _ := url.Parse(signed)

		signed = base + "/minio" + parsed.Path + "?" + parsed.RawQuery
	}

	return signed, nil
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

	u, err := s.signer.PresignedGetObject(ctx, s.bucket, key, ttl, q)
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

	u, err := s.signer.PresignedPutObject(ctx, s.bucket, key, ttl)
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

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

	return key, nil
}

func (s *MinioStorage) Stat(ctx context.Context, key string) (*ObjectStat, error) {
	st, err := s.internal.StatObject(ctx, s.bucket, key, minio.StatObjectOptions{})
	if err != nil {
		return nil, err
	}
	return &ObjectStat{Size: st.Size, ETag: st.ETag, MIMEType: st.ContentType}, nil
}

func (s *MinioStorage) Delete(ctx context.Context, key string) error {
	return s.internal.RemoveObject(ctx, s.bucket, key, minio.RemoveObjectOptions{})
}

func (s *MinioStorage) Config() *config.MinioConfig {
	return s.cfg
}

func (s *MinioStorage) Download(ctx context.Context, key string) ([]byte, error) {
	obj, err := s.internal.GetObject(ctx, s.bucket, key, minio.GetObjectOptions{})
	if err != nil {
		return nil, fmt.Errorf("get object %s: %w", key, err)
	}
	defer obj.Close()

	var buf bytes.Buffer
	if _, err := io.Copy(&buf, obj); err != nil {
		return nil, fmt.Errorf("read object %s: %w", key, err)
	}

	return buf.Bytes(), nil
}
