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

// =============================
//  Struct & Globals
// =============================

type MinioStorage struct {
	internal *minio.Client // 🔌 สำหรับ Upload/Delete (คุยกับ minio:9000 ภายใน)
	signer   *minio.Client // ✍️ สำหรับสร้าง Presigned URL (คุยกับ Public Domain)
	bucket   string
	cfg      *config.MinioConfig
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

// ฟังก์ชันนี้ใช้สำหรับสร้าง MinIO แบบ Standalone (ถ้ามีใช้ที่อื่น)
func NewMinioStorage(opt MinioOptions) (*MinioStorage, error) {
	// 1. Internal Client (minio:9000)
	internal, err := minio.New(opt.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(opt.AccessKey, opt.SecretKey, ""),
		Secure: false, // ภายในมักเป็น HTTP
		Region: opt.Region,
	})
	if err != nil {
		return nil, fmt.Errorf("init internal client: %w", err)
	}

	// 2. Signer Client (Public HTTPS)
	publicHost := opt.PublicBaseURL
	if publicHost == "" {
		publicHost = opt.Endpoint
	}
	// Clean Host
	publicHost = strings.TrimPrefix(publicHost, "http://")
	publicHost = strings.TrimPrefix(publicHost, "https://")

	signer, err := minio.New(publicHost, &minio.Options{
		Creds:  credentials.NewStaticV4(opt.AccessKey, opt.SecretKey, ""),
		Secure: opt.UseSSL, // ใช้ SSL ตาม Config (ควรเป็น true)
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

	// ใช้ Internal เช็ค Bucket
	if err := s.ensureBucket(context.Background()); err != nil {
		return nil, err
	}

	return s, nil
}

// ฟังก์ชันหลักที่ใช้กับ Config App
func NewMinioFromConfig(c config.MinioConfig) (*MinioStorage, error) {
	// 1. Setup Internal Client (HTTP -> minio:9000)
	// ใช้สำหรับการทำงาน backend จริงๆ
	internalClient, err := minio.New(c.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(c.AccessKey, c.SecretKey, ""),
		Secure: false, // สำคัญ: ภายใน Docker คุยกันเองมักไม่ผ่าน SSL
		Region: c.Region,
	})
	if err != nil {
		return nil, fmt.Errorf("init internal client: %w", err)
	}

	// 2. Setup Signer Client (HTTPS -> cp25ssa1...:8081)
	// ใช้สำหรับสร้าง URL ให้ Frontend เท่านั้น
	publicHost := c.PublicBaseURL
	if publicHost == "" {
		publicHost = c.Endpoint
	}

	// ลบ http/https ออก เพราะ minio.New ต้องการแค่ host:port
	publicHost = strings.TrimPrefix(publicHost, "http://")
	publicHost = strings.TrimPrefix(publicHost, "https://")

	signerClient, err := minio.New(publicHost, &minio.Options{
		Creds:  credentials.NewStaticV4(c.AccessKey, c.SecretKey, ""),
		Secure: c.UseSSL, // ตรงนี้สำคัญ! ถ้า Public เป็น HTTPS ต้องเป็น true
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

// =============================
//  Bucket Handling
// =============================

func (s *MinioStorage) ensureBucket(ctx context.Context) error {
	// ใช้ Internal Client จัดการ Bucket
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

	// ใช้ Internal Client อัปโหลด (เร็ว + เสถียร)
	info, err := s.internal.PutObject(ctx, s.bucket, key, r, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return minio.UploadInfo{}, fmt.Errorf("put object: %w", err)
	}
	return info, nil
}

// =============================
//  Presigned URLs (พระเอกของเรา)
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

	// ✨ ใช้ Signer Client
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

	// ✨ ใช้ Signer Client
	u, err := s.signer.PresignedPutObject(ctx, s.bucket, key, ttl)
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

// =============================
//  Upload File
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

	// Put เรียก Internal Client อยู่แล้ว
	_, err := s.Put(ctx, key, r, size, contentType)
	if err != nil {
		return "", err
	}

	return key, nil
}

// =============================
//  Helpers
// =============================

func (s *MinioStorage) Stat(ctx context.Context, key string) (*ObjectStat, error) {
	// ใช้ Internal Client
	st, err := s.internal.StatObject(ctx, s.bucket, key, minio.StatObjectOptions{})
	if err != nil {
		return nil, err
	}
	return &ObjectStat{Size: st.Size, ETag: st.ETag, MIMEType: st.ContentType}, nil
}

func (s *MinioStorage) Delete(ctx context.Context, key string) error {
	// ใช้ Internal Client
	return s.internal.RemoveObject(ctx, s.bucket, key, minio.RemoveObjectOptions{})
}

func (s *MinioStorage) Config() *config.MinioConfig {
	return s.cfg
}
