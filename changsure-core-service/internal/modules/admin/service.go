package admin

import (
	"context"
	"fmt"
	"io"
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/pkg/storage"
)

const (
	avatarFolder  = "admins/avatars"
	presignGetTTL = 60 * time.Minute
)

type Service interface {
	UpdateProfile(ctx context.Context, adminID uint, req SetupProfileRequest, avatarFile *AvatarFile) (*ProfileResponse, error)
	GetProfile(ctx context.Context, adminID uint) (*ProfileResponse, error)
	UpdateAvatar(ctx context.Context, adminID uint, file io.Reader, size int64, contentType string) (*ProfileResponse, error)
}

type AvatarFile struct {
	Reader      io.Reader
	Size        int64
	ContentType string
}

type service struct {
	repo    Repository
	storage storage.Storage
}

func NewService(repo Repository, store storage.Storage) Service {
	return &service{repo: repo, storage: store}
}

func (s *service) UpdateProfile(ctx context.Context, adminID uint, req SetupProfileRequest, avatarFile *AvatarFile) (*ProfileResponse, error) {
	admin, err := s.repo.FindByID(ctx, adminID)
	if err != nil {
		return nil, appErrors.NewInternal(err)
	}
	if admin == nil {
		return nil, appErrors.NewNotFound("admin not found")
	}

	admin.FirstName = req.FirstName
	admin.LastName = req.LastName

	if avatarFile != nil {
		key, err := s.uploadAvatar(ctx, adminID, avatarFile)
		if err != nil {
			return nil, err
		}
		admin.Avatar = &key
	}

	if err := s.repo.Update(ctx, admin); err != nil {
		return nil, appErrors.NewInternal(err)
	}

	return s.toProfileResponse(ctx, admin)
}

func (s *service) GetProfile(ctx context.Context, adminID uint) (*ProfileResponse, error) {
	admin, err := s.repo.FindByID(ctx, adminID)
	if err != nil {
		return nil, appErrors.NewInternal(err)
	}
	if admin == nil {
		return nil, appErrors.NewNotFound("admin not found")
	}

	return s.toProfileResponse(ctx, admin)
}

func (s *service) UpdateAvatar(ctx context.Context, adminID uint, file io.Reader, size int64, contentType string) (*ProfileResponse, error) {
	admin, err := s.repo.FindByID(ctx, adminID)
	if err != nil {
		return nil, appErrors.NewInternal(err)
	}
	if admin == nil {
		return nil, appErrors.NewNotFound("admin not found")
	}

	key, err := s.uploadAvatar(ctx, adminID, &AvatarFile{
		Reader:      file,
		Size:        size,
		ContentType: contentType,
	})
	if err != nil {
		return nil, err
	}

	admin.Avatar = &key
	if err := s.repo.Update(ctx, admin); err != nil {
		return nil, appErrors.NewInternal(err)
	}

	return s.toProfileResponse(ctx, admin)
}

func (s *service) uploadAvatar(ctx context.Context, adminID uint, f *AvatarFile) (string, error) {
	filename := fmt.Sprintf("%d_%d", adminID, time.Now().UnixNano())
	key, err := s.storage.UploadFile(ctx, f.Reader, filename, avatarFolder, f.Size, f.ContentType)
	if err != nil {
		return "", appErrors.NewInternal(err)
	}
	return key, nil
}

func (s *service) toProfileResponse(ctx context.Context, a *Admin) (*ProfileResponse, error) {
	resp := &ProfileResponse{
		ID:        a.ID,
		FirstName: a.FirstName,
		LastName:  a.LastName,
		Email:     a.Email,
	}

	if a.Avatar != nil && *a.Avatar != "" {
		url, err := s.storage.PresignGet(ctx, *a.Avatar, presignGetTTL, false)
		if err != nil {
			return nil, appErrors.NewInternal(err)
		}
		resp.AvatarURL = &url
	}

	return resp, nil
}
