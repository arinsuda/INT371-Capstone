package verification

import (
	"context"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	
	"changsure-core-service/configs"
	"changsure-core-service/pkg/storage"
)

type Service interface {
	PresignUpload(ctx context.Context, techID uint64, docType, fileName, contentType string) (uploadURL, objectKey string, err error)
	PresignDownload(ctx context.Context, objectKey string) (string, error)
	ConfirmUpload(ctx context.Context, input ConfirmInput) error
}

type service struct {
	cfg   *configs.Config
	store storage.ObjectStorage
	repo  Repository
	db    *gorm.DB
}

type ConfirmInput struct {
	TechnicianID uint64
	DocType      string
	ObjectKey    string
	Notes        *string
}

func NewService(cfg *configs.Config, store storage.ObjectStorage, repo Repository, db *gorm.DB) Service {
	return &service{cfg: cfg, store: store, repo: repo, db: db}
}

func (s *service) PresignUpload(ctx context.Context, techID uint64, docType, fileName, contentType string) (string, string, error) {
	// validate doc type
	if _, ok := s.cfg.Minio.AllowDocTypesSet[docType]; !ok {
		return "", "", fmt.Errorf("doc_type not allowed")
	}
	ext := strings.ToLower(filepath.Ext(fileName))
	if ext == "" {
		ext = ".bin"
	}

	objectKey := fmt.Sprintf("technicians/%d/%s/%s%s", techID, docType, uuid.NewString(), ext)
	url, err := s.store.PresignPut(ctx, objectKey, contentType, time.Duration(s.cfg.Minio.PresignUploadTTL)*time.Second)
	if err != nil {
		return "", "", err
	}
	return url, objectKey, nil
}

func (s *service) PresignDownload(ctx context.Context, objectKey string) (string, error) {
	return s.store.PresignGet(ctx, objectKey, time.Duration(s.cfg.Minio.PresignDownloadTTL)*time.Second, true)
}

func (s *service) ConfirmUpload(ctx context.Context, in ConfirmInput) error {
	// อ่าน stat จาก object (ไว้เก็บ meta ถ้าต้องการ)
	if _, err := s.store.Stat(ctx, in.ObjectKey); err != nil {
		return fmt.Errorf("object not found: %w", err)
	}

	// บันทึกเรคคอร์ดใหม่ (เก็บเป็น URL รูป s3://bucket/key หรือเก็บ key อย่างเดียวก็ได้)
	docURL := fmt.Sprintf("s3://%s/%s", s.cfg.Minio.Minio.Bucket, in.ObjectKey) // ถ้าใช้ key อย่างเดียว เปลี่ยนเป็น in.ObjectKey

	v := &TechnicianVerification{
		TechnicianID: in.TechnicianID,
		DocType:      in.DocType,
		DocURL:       docURL,
		VerifyStatus: "pending",
		Notes:        in.Notes,
	}

	return s.repo.Create(v)
}
