package document

import (
	"errors"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Repository interface {
	CreateDocument(doc *Document) error
	GetBySlug(slug string) (*Document, error)
	CreateVersion(v *DocumentVersion) error
	LatestVersion(docID uuid.UUID, locale string) (int, error)
	GetPublished(slug, locale string) (*DocumentVersion, error)
	UnpublishAll(tx *gorm.DB, docID uuid.UUID, locale string) error
	Publish(tx *gorm.DB, docID uuid.UUID, locale string, version int) error
	Accept(a *DocumentAcceptance) error
}

type repository struct {
	DB *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{DB: db}
}

func (r *repository) CreateDocument(doc *Document) error {
	return r.DB.Create(doc).Error
}

func (r *repository) GetBySlug(slug string) (*Document, error) {
	var doc Document
	err := r.DB.Where("slug = ?", slug).First(&doc).Error
	if err != nil {
		return nil, err
	}
	return &doc, nil
}

func (r *repository) CreateVersion(v *DocumentVersion) error {
	return r.DB.Create(v).Error
}

func (r *repository) LatestVersion(docID uuid.UUID, locale string) (int, error) {
	var max int
	err := r.DB.Model(&DocumentVersion{}).
		Where("document_id = ? AND locale = ?", docID, locale).
		Select("COALESCE(MAX(version),0)").Scan(&max).Error
	return max, err
}

func (r *repository) GetPublished(slug, locale string) (*DocumentVersion, error) {
	var v DocumentVersion
	err := r.DB.
		Joins("JOIN documents d ON d.id = document_versions.document_id").
		Where("d.slug=? AND document_versions.locale=? AND is_published=true", slug, locale).
		Order("version DESC").
		First(&v).Error

	if err != nil {
		return nil, err
	}
	return &v, nil
}

func (r *repository) UnpublishAll(tx *gorm.DB, docID uuid.UUID, locale string) error {
	return tx.Model(&DocumentVersion{}).
		Where("document_id=? AND locale=?", docID, locale).
		Update("is_published", false).Error
}

func (r *repository) Publish(tx *gorm.DB, docID uuid.UUID, locale string, version int) error {
	res := tx.Model(&DocumentVersion{}).
		Where("document_id=? AND locale=? AND version=?", docID, locale, version).
		Updates(map[string]interface{}{
			"is_published": true,
			"published_at": gorm.Expr("NOW()"),
		})
	if res.RowsAffected == 0 {
		return errors.New("version not found")
	}
	return res.Error
}

func (r *repository) Accept(a *DocumentAcceptance) error {
	return r.DB.Create(a).Error
}
