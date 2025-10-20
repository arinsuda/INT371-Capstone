package validator

import (
	"bytes"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strings"

	"changsure-core-service/internal/modules/ocr/config"
	ocrErrors "changsure-core-service/internal/modules/ocr/errors"
)

type FileValidator struct {
	config *config.OCRConfig
}

func NewFileValidator(cfg *config.OCRConfig) *FileValidator {
	return &FileValidator{config: cfg}
}

func (v *FileValidator) ValidateFile(fileHeader *multipart.FileHeader) error {
	if fileHeader == nil {
		return ocrErrors.NewInvalidFileError("file header is nil", nil)
	}

	if v.config != nil && v.config.MaxFileSize > 0 && fileHeader.Size > v.config.MaxFileSize {
		return ocrErrors.NewFileTooLargeError(v.config.MaxFileSize)
	}

	file, err := fileHeader.Open()
	if err != nil {
		return ocrErrors.NewInvalidFileError("failed to open file", err)
	}
	defer file.Close()

	sniff := make([]byte, 512)
	n, _ := file.Read(sniff)
	contentType := http.DetectContentType(sniff[:n])

	if contentType == "application/octet-stream" {
		if ext := strings.ToLower(filepath.Ext(fileHeader.Filename)); ext != "" {
			switch ext {
			case ".jpg", ".jpeg":
				contentType = "image/jpeg"
			case ".png":
				contentType = "image/png"
			case ".webp":
				contentType = "image/webp"
			case ".heic":
				contentType = "image/heic"
			case ".heif":
				contentType = "image/heif"
			}
		}
	}

	if !v.isAllowedFormat(contentType, fileHeader.Filename) {
		return ocrErrors.NewUnsupportedFormatError(contentType)
	}

	return nil
}

func (v *FileValidator) ValidateFileBytes(data []byte, filename string) error {
	if data == nil {
		return ocrErrors.NewInvalidFileError("file bytes is nil", nil)
	}
	if v.config != nil && v.config.MaxFileSize > 0 && int64(len(data)) > v.config.MaxFileSize {
		return ocrErrors.NewFileTooLargeError(v.config.MaxFileSize)
	}
	contentType := http.DetectContentType(first512(data))
	if contentType == "application/octet-stream" {
		if ext := strings.ToLower(filepath.Ext(filename)); ext != "" {
			switch ext {
			case ".jpg", ".jpeg":
				contentType = "image/jpeg"
			case ".png":
				contentType = "image/png"
			case ".webp":
				contentType = "image/webp"
			case ".heic":
				contentType = "image/heic"
			case ".heif":
				contentType = "image/heif"
			}
		}
	}
	if !v.isAllowedFormat(contentType, filename) {
		return ocrErrors.NewUnsupportedFormatError(contentType)
	}
	return nil
}

func (v *FileValidator) isAllowedFormat(contentType string, filename string) bool {
	allowed := []string{"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"}
	if v.config != nil && len(v.config.AllowedFormats) > 0 {
		allowed = v.config.AllowedFormats
	}
	for _, a := range allowed {
		if contentType == a {
			return true
		}
	}
	ext := strings.ToLower(filepath.Ext(filename))
	if strings.HasPrefix(contentType, "image/") && (ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".webp" || ext == ".heic" || ext == ".heif") {
		return true
	}
	return false
}

func ReadFileBytes(fileHeader *multipart.FileHeader) ([]byte, error) {
	if fileHeader == nil {
		return nil, ocrErrors.NewInvalidFileError("file header is nil", nil)
	}
	file, err := fileHeader.Open()
	if err != nil {
		return nil, ocrErrors.NewInvalidFileError("failed to open file", err)
	}
	defer file.Close()

	buf := new(bytes.Buffer)
	if _, err := buf.ReadFrom(file); err != nil {
		return nil, ocrErrors.NewInvalidFileError("failed to read file", err)
	}
	return buf.Bytes(), nil
}

func first512(b []byte) []byte {
	if len(b) > 512 {
		return b[:512]
	}
	return b
}
