package provider

import (
	"bytes"
	"context"
	"image"
	"image/png"
)

// DefaultRegionDetector implements RegionDetector interface
type DefaultRegionDetector struct{}

func NewDefaultRegionDetector() RegionDetector {
	return &DefaultRegionDetector{}
}

// DetectIDNumberRegion ตรวจจับพื้นที่เลขบัตรประชาชน
func (r *DefaultRegionDetector) DetectIDNumberRegion(ctx context.Context, imageData []byte) (*Region, error) {
	// ลองหลายตำแหน่งสำหรับบัตรจริง
	// บัตรประชาชนไทยมีเลขอยู่ตรงกลาง-บน

	// Option 1: ตำแหน่งมาตรฐาน
	return &Region{
		X:          0.20, // เริ่มจากซ้าย 20%
		Y:          0.12, // จากบน 12%
		Width:      0.60, // กว้าง 60%
		Height:     0.10, // สูง 10%
		Confidence: 0.9,
		Type:       "id_number",
	}, nil
}

// DetectNameRegion ตรวจจับพื้นที่ชื่อ
func (r *DefaultRegionDetector) DetectNameRegion(ctx context.Context, imageData []byte) (*Region, error) {
	// ชื่ออยู่ใต้เลขบัตร
	return &Region{
		X:          0.25,
		Y:          0.25,
		Width:      0.50,
		Height:     0.10,
		Confidence: 0.8,
		Type:       "name",
	}, nil
}

// DetectAllRegions ตรวจจับทุกพื้นที่
func (r *DefaultRegionDetector) DetectAllRegions(ctx context.Context, imageData []byte) ([]*Region, error) {
	var regions []*Region

	// ID Number
	if idRegion, err := r.DetectIDNumberRegion(ctx, imageData); err == nil {
		regions = append(regions, idRegion)
	}

	// Name
	if nameRegion, err := r.DetectNameRegion(ctx, imageData); err == nil {
		regions = append(regions, nameRegion)
	}

	return regions, nil
}

// CropRegion ตัดภาพตาม region
func (r *DefaultRegionDetector) CropRegion(ctx context.Context, imageData []byte, region *Region) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}

	bounds := img.Bounds()
	width := bounds.Dx()
	height := bounds.Dy()

	// แปลง normalized coordinates เป็น pixel coordinates
	x1 := int(region.X * float64(width))
	y1 := int(region.Y * float64(height))
	x2 := int((region.X + region.Width) * float64(width))
	y2 := int((region.Y + region.Height) * float64(height))

	// Clamp to bounds
	if x1 < 0 {
		x1 = 0
	}
	if y1 < 0 {
		y1 = 0
	}
	if x2 > width {
		x2 = width
	}
	if y2 > height {
		y2 = height
	}

	// Create cropped image
	cropped := image.NewRGBA(image.Rect(0, 0, x2-x1, y2-y1))
	for y := y1; y < y2; y++ {
		for x := x1; x < x2; x++ {
			cropped.Set(x-x1, y-y1, img.At(x, y))
		}
	}

	// Encode to bytes
	buf := new(bytes.Buffer)
	err = png.Encode(buf, cropped)
	if err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}
