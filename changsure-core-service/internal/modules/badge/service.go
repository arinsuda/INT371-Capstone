package badge

import (
	"bytes"
	"changsure-core-service/pkg/imageutil"
	"changsure-core-service/pkg/storage"
	"context"
	"errors"
	"fmt"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
)

type Service interface {
	CreateBadge(ctx context.Context, dto CreateBadgeDTO) (*Badge, error)
	UpdateBadge(ctx context.Context, id uint, dto UpdateBadgeDTO) (*Badge, error)
	UpdateBadgeWithFile(ctx context.Context, id uint, dto UpdateBadgeDTO, fileHeader *multipart.FileHeader) (*Badge, error)
	SoftDeleteBadge(ctx context.Context, id uint) error
	RestoreBadge(ctx context.Context, id uint) error
	HardDeleteBadge(ctx context.Context, id uint) error
	ListBadges(ctx context.Context, q ListBadgesQuery) ([]Badge, int64, error)
	FindBadge(ctx context.Context, id uint, includeDeleted bool) (*Badge, error)
}

type service struct {
	repo  Repository
	store storage.Storage
}

func NewService(repo Repository, store storage.Storage) Service {
	return &service{repo: repo, store: store}
}

func (s *service) CreateBadge(ctx context.Context, dto CreateBadgeDTO) (*Badge, error) {
	b := &Badge{
		Name: dto.Name,
		IconURL: func() string {
			if dto.IconURL == nil {
				return ""
			}
			return normalizeIconKey(*dto.IconURL)
		}(),
		Level: func() uint {
			if dto.Level == nil {
				return 0
			}
			return *dto.Level
		}(),
		IsActive: func() bool {
			if dto.IsActive == nil {
				return true
			}
			return *dto.IsActive
		}(),
		Description: func() string {
			if dto.Description == nil {
				return ""
			}
			return *dto.Description
		}(),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := s.repo.CreateBadge(ctx, b); err != nil {
		return nil, err
	}

	return b, nil
}

func (s *service) UpdateBadge(ctx context.Context, id uint, dto UpdateBadgeDTO) (*Badge, error) {
	b, err := s.repo.FindBadgeById(ctx, id, true)
	if err != nil {
		return nil, err
	}

	if dto.Name != nil {
		b.Name = *dto.Name
	}
	if dto.IconURL != nil {
		b.IconURL = normalizeIconKey(*dto.IconURL)
	}
	if dto.Level != nil {
		b.Level = *dto.Level
	}
	if dto.IsActive != nil {
		b.IsActive = *dto.IsActive
	}
	if dto.Description != nil {
		b.Description = *dto.Description
	}

	b.UpdatedAt = time.Now()

	if err := s.repo.UpdateBadge(ctx, b); err != nil {
		return nil, err
	}

	return b, nil
}

func (s *service) UpdateBadgeWithFile(
	ctx context.Context,
	id uint,
	dto UpdateBadgeDTO,
	fileHeader *multipart.FileHeader,
) (*Badge, error) {

	b, err := s.repo.FindBadgeById(ctx, id, true)
	if err != nil {
		return nil, err
	}

	// ---------- handle file upload ----------
	if fileHeader != nil {

		if fileHeader.Size > 2_000_000 {
			return nil, errors.New("file too large (max 2MB)")
		}

		file, err := fileHeader.Open()
		if err != nil {
			return nil, err
		}
		defer file.Close()

		var raw bytes.Buffer
		raw.ReadFrom(file)

		imgBuf, err := imageutil.OptimizeImage(bytes.NewReader(raw.Bytes()), imageutil.ResizeOptions{
			MaxWidth:    512,
			MaxFileSize: 500_000,
			Quality:     85,
		})
		if err != nil {
			return nil, errors.New("invalid image")
		}

		ext := strings.ToLower(filepath.Ext(fileHeader.Filename))
		if ext == "" {
			ext = ".png"
		}

		key := fmt.Sprintf(
			"badges/%d/%d_%s%s",
			id,
			time.Now().Unix(),
			uuid.NewString(),
			ext,
		)

		contentType := http.DetectContentType(imgBuf.Bytes())

		_, err = s.store.Put(ctx, key,
			bytes.NewReader(imgBuf.Bytes()),
			int64(imgBuf.Len()),
			contentType,
		)
		if err != nil {
			return nil, err
		}

		// delete old file
		if b.IconURL != "" {
			_ = s.store.Delete(ctx, b.IconURL)
		}

		dto.IconURL = &key
	}

	// ---------- update fields ----------
	if dto.Name != nil {
		b.Name = *dto.Name
	}
	if dto.IconURL != nil {
		b.IconURL = *dto.IconURL
	}
	if dto.Level != nil {
		b.Level = *dto.Level
	}
	if dto.IsActive != nil {
		b.IsActive = *dto.IsActive
	}
	if dto.Description != nil {
		b.Description = *dto.Description
	}

	b.UpdatedAt = time.Now()

	if err := s.repo.UpdateBadge(ctx, b); err != nil {
		return nil, err
	}

	return b, nil
}

func (s *service) SoftDeleteBadge(ctx context.Context, id uint) error {
	return s.repo.SoftDelete(ctx, id)
}

func (s *service) RestoreBadge(ctx context.Context, id uint) error {
	return s.repo.RestoreBadge(ctx, id)
}

func (s *service) HardDeleteBadge(ctx context.Context, id uint) error {
	b, err := s.repo.FindBadgeById(ctx, id, true)
	if err != nil {
		return err
	}

	if b.IconURL != "" {
		_ = s.store.Delete(ctx, b.IconURL)
	}

	return s.repo.HardDelete(ctx, id)
}

func (s *service) ListBadges(ctx context.Context, q ListBadgesQuery) ([]Badge, int64, error) {
	return s.repo.ListBadges(ctx, q)
}

func (s *service) FindBadge(ctx context.Context, id uint, includeDeleted bool) (*Badge, error) {
	return s.repo.FindBadgeById(ctx, id, includeDeleted)
}
