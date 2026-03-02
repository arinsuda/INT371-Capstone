package document

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type Service interface {
	CreateDocument(dto CreateDocumentDTO) (*DocumentResponse, error)
	CreateVersion(slug string, dto CreateVersionDTO) (*VersionResponse, error)
	Publish(slug string, version int, locale string) error
	GetPublished(slug, locale string) (*PublishedResponse, error)
	Accept(slug string, userID uint, role string, locale string) (*AcceptanceResponse, error)
}

type service struct {
	repo Repository
	db   *gorm.DB
}

func NewService(r Repository, db *gorm.DB) Service {
	return &service{r, db}
}

func (s *service) CreateDocument(dto CreateDocumentDTO) (*DocumentResponse, error) {
	doc := &Document{
		Type: dto.Type,
		Slug: dto.Slug,
	}
	if err := s.repo.CreateDocument(doc); err != nil {
		return nil, err
	}
	return &DocumentResponse{
		ID:   doc.ID.String(),
		Type: doc.Type,
		Slug: doc.Slug,
	}, nil
}

func (s *service) CreateVersion(slug string, dto CreateVersionDTO) (*VersionResponse, error) {
	doc, err := s.repo.GetBySlug(slug)
	if err != nil {
		return nil, err
	}

	latest, err := s.repo.LatestVersion(doc.ID, dto.Locale)
	if err != nil {
		return nil, err
	}

	v := &DocumentVersion{
		ID:         uuid.New(),
		DocumentID: doc.ID,
		Version:    latest + 1,
		Locale:     dto.Locale,
		Content:    datatypes.JSON(dto.Content),
	}

	if err := s.repo.CreateVersion(v); err != nil {
		return nil, err
	}

	return &VersionResponse{
		ID:          v.ID.String(),
		DocumentID:  doc.ID.String(),
		Version:     v.Version,
		Locale:      v.Locale,
		Content:     dto.Content,
		IsPublished: false,
	}, nil
}

func (s *service) Publish(slug string, version int, locale string) error {
	doc, err := s.repo.GetBySlug(slug)
	if err != nil {
		return err
	}

	return s.db.Transaction(func(tx *gorm.DB) error {
		if err := s.repo.UnpublishAll(tx, doc.ID, locale); err != nil {
			return err
		}
		return s.repo.Publish(tx, doc.ID, locale, version)
	})
}

func (s *service) GetPublished(slug, locale string) (*PublishedResponse, error) {
	v, err := s.repo.GetPublished(slug, locale)
	if err != nil {
		return nil, err
	}

	return &PublishedResponse{
		Slug:    slug,
		Version: v.Version,
		Locale:  v.Locale,
		Content: json.RawMessage(v.Content),
	}, nil
}

func (s *service) Accept(slug string, userID uint, role string, locale string) (*AcceptanceResponse, error) {
	doc, err := s.repo.GetBySlug(slug)
	if err != nil {
		return nil, err
	}

	v, err := s.repo.GetPublished(slug, locale)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	a := &DocumentAcceptance{
		ID:         uuid.New(),
		UserID:     userID,
		UserRole:   role,
		DocumentID: doc.ID,
		Version:    v.Version,
		AcceptedAt: now,
	}

	if err := s.repo.Accept(a); err != nil {
		return nil, err
	}

	return &AcceptanceResponse{
		ID:         a.ID.String(),
		UserID:     uint(a.UserID),
		UserRole:   role,
		DocumentID: doc.ID.String(),
		Version:    v.Version,
		AcceptedAt: now,
		Locale:     locale,
	}, nil
}
