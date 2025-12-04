package imageutil

import (
	"bytes"
	"errors"
	"image"
	"io"

	_ "image/jpeg"
	_ "image/png"

	"github.com/disintegration/imaging"
)

var (
	ErrInvalidFormat = errors.New("invalid image format")
	ErrTooLarge      = errors.New("image file too large")
)

type ResizeOptions struct {
	MaxWidth    int
	MaxFileSize int
	Quality     int
}

func OptimizeImage(src io.Reader, opts ResizeOptions) (*bytes.Buffer, error) {

	limitedReader := io.LimitReader(src, int64(opts.MaxFileSize*3))

	img, _, err := image.Decode(limitedReader)
	if err != nil {

		return nil, ErrInvalidFormat
	}

	if opts.MaxWidth > 0 {
		img = imaging.Resize(img, opts.MaxWidth, 0, imaging.Lanczos)
	}

	out := new(bytes.Buffer)
	if err := imaging.Encode(out, img, imaging.JPEG, imaging.JPEGQuality(opts.Quality)); err != nil {
		return nil, err
	}

	if out.Len() > opts.MaxFileSize {
		return nil, ErrTooLarge
	}

	return out, nil
}
