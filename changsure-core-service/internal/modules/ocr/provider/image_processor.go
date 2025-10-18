package provider

import (
	"bytes"
	"context"
	"image"
	"image/color"
	"image/png"
)

// DefaultImageProcessor implements ImageProcessor interface
type DefaultImageProcessor struct {
	// config ถ้าต้องการ
}

func NewDefaultImageProcessor() ImageProcessor {
	return &DefaultImageProcessor{}
}

// Preprocess ปรับแต่งภาพตาม options
func (p *DefaultImageProcessor) Preprocess(ctx context.Context, imageData []byte, opts *PreprocessOptions) ([]byte, error) {
	if opts == nil {
		return imageData, nil
	}

	currentData := imageData
	var err error

	// Apply transformations ตามลำดับ
	if opts.Grayscale {
		currentData, err = p.ConvertToGrayscale(ctx, currentData)
		if err != nil {
			return nil, err
		}
	}

	if opts.Normalize {
		currentData, err = p.Normalize(ctx, currentData)
		if err != nil {
			return nil, err
		}
	}

	if opts.EnhanceContrast {
		currentData, err = p.EnhanceContrast(ctx, currentData)
		if err != nil {
			return nil, err
		}
	}

	if opts.Upscale > 1.0 {
		currentData, err = p.Upscale(ctx, currentData, opts.Upscale)
		if err != nil {
			return nil, err
		}
	}

	if opts.AutoRotate {
		currentData, _, err = p.AutoRotate(ctx, currentData)
		if err != nil {
			return nil, err
		}
	}

	return currentData, nil
}

// Normalize ปรับ brightness/contrast ให้เป็น standard
func (p *DefaultImageProcessor) Normalize(ctx context.Context, imageData []byte) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}

	bounds := img.Bounds()
	normalized := image.NewGray(bounds)

	// Convert to grayscale and apply contrast enhancement
	for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
		for x := bounds.Min.X; x < bounds.Max.X; x++ {
			r, g, b, _ := img.At(x, y).RGBA()
			// Convert to grayscale
			gray := uint8((0.299*float64(r) + 0.587*float64(g) + 0.114*float64(b)) / 256)

			// Apply contrast enhancement (factor 2.5)
			enhanced := float64(gray)
			enhanced = ((enhanced/255.0 - 0.5) * 2.5 + 0.5) * 255.0

			if enhanced > 255 {
				enhanced = 255
			} else if enhanced < 0 {
				enhanced = 0
			}

			normalized.SetGray(x, y, color.Gray{Y: uint8(enhanced)})
		}
	}

	return encodeImage(normalized)
}

// Upscale ขยายภาพ
func (p *DefaultImageProcessor) Upscale(ctx context.Context, imageData []byte, scale float64) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}

	bounds := img.Bounds()
	oldWidth := bounds.Dx()
	oldHeight := bounds.Dy()
	newWidth := int(float64(oldWidth) * scale)
	newHeight := int(float64(oldHeight) * scale)

	// Nearest neighbor scaling
	upscaled := image.NewRGBA(image.Rect(0, 0, newWidth, newHeight))
	for y := 0; y < newHeight; y++ {
		for x := 0; x < newWidth; x++ {
			srcX := int(float64(x) / scale)
			srcY := int(float64(y) / scale)
			if srcX >= oldWidth {
				srcX = oldWidth - 1
			}
			if srcY >= oldHeight {
				srcY = oldHeight - 1
			}
			upscaled.Set(x, y, img.At(srcX, srcY))
		}
	}

	return encodeImage(upscaled)
}

// AutoRotate หมุนภาพอัตโนมัติ (ตอนนี้ return ภาพเดิมก่อน)
func (p *DefaultImageProcessor) AutoRotate(ctx context.Context, imageData []byte) ([]byte, float64, error) {
	// TODO: Implement actual rotation detection
	// ตอนนี้ return ภาพเดิมและ angle = 0
	return imageData, 0.0, nil
}

// ConvertToGrayscale แปลงเป็นภาพขาวดำ
func (p *DefaultImageProcessor) ConvertToGrayscale(ctx context.Context, imageData []byte) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}

	bounds := img.Bounds()
	gray := image.NewGray(bounds)

	for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
		for x := bounds.Min.X; x < bounds.Max.X; x++ {
			gray.Set(x, y, color.GrayModel.Convert(img.At(x, y)))
		}
	}

	return encodeImage(gray)
}

// EnhanceContrast เพิ่มความชัดของภาพ
func (p *DefaultImageProcessor) EnhanceContrast(ctx context.Context, imageData []byte) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}

	// Convert to Gray if not already
	var grayImg *image.Gray
	if g, ok := img.(*image.Gray); ok {
		grayImg = g
	} else {
		bounds := img.Bounds()
		grayImg = image.NewGray(bounds)
		for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
			for x := bounds.Min.X; x < bounds.Max.X; x++ {
				grayImg.Set(x, y, color.GrayModel.Convert(img.At(x, y)))
			}
		}
	}

	// Apply contrast enhancement
	bounds := grayImg.Bounds()
	enhanced := image.NewGray(bounds)
	factor := 1.8 // contrast factor

	for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
		for x := bounds.Min.X; x < bounds.Max.X; x++ {
			gray := grayImg.GrayAt(x, y).Y
			v := float64(gray)

			// Apply contrast formula
			newV := ((v/255.0 - 0.5) * factor + 0.5) * 255.0

			if newV > 255 {
				newV = 255
			} else if newV < 0 {
				newV = 0
			}

			enhanced.SetGray(x, y, color.Gray{Y: uint8(newV)})
		}
	}

	return encodeImage(enhanced)
}

// encodeImage helper function
func encodeImage(img image.Image) ([]byte, error) {
	buf := new(bytes.Buffer)
	err := png.Encode(buf, img)
	if err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}