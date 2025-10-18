package provider

import (
	"bytes"
	"context"
	"image"
	"image/png"
)

// DefaultRegionDetector implements RegionDetector interface
type DefaultRegionDetector struct {
	// config ถ้าต้องการ
}

func NewDefaultRegionDetector() RegionDetector {
	return &DefaultRegionDetector{}
}

// DetectIDNumberRegion ตรวจหาตำแหน่งเลขบัตรประชาชน
func (d *DefaultRegionDetector) DetectIDNumberRegion(ctx context.Context, imageData []byte) (*Region, error) {
	// ใช้ตำแหน่งมาตรฐานของบัตรประชาชนไทย
	// เลขบัตรอยู่ด้านบนตรงกลาง
	return &Region{
		X:          0.30, // เริ่มจากซ้าย 30%
		Y:          0.12, // เริ่มจากบน 12%
		Width:      0.55, // กว้าง 55%
		Height:     0.08, // สูง 8%
		Confidence: 0.95, // confidence สูงเพราะเป็นตำแหน่งมาตรฐาน
		Type:       "id_number",
	}, nil
}

// DetectNameRegion ตรวจหาตำแหน่งชื่อ
func (d *DefaultRegionDetector) DetectNameRegion(ctx context.Context, imageData []byte) (*Region, error) {
	return &Region{
		X:          0.20,
		Y:          0.35,
		Width:      0.50,
		Height:     0.08,
		Confidence: 0.90,
		Type:       "name",
	}, nil
}

// DetectAllRegions ตรวจหาตำแหน่งทั้งหมด
func (d *DefaultRegionDetector) DetectAllRegions(ctx context.Context, imageData []byte) ([]*Region, error) {
	regions := []*Region{
		// เลขบัตร
		{
			X:          0.30,
			Y:          0.12,
			Width:      0.55,
			Height:     0.08,
			Confidence: 0.95,
			Type:       "id_number",
		},
		// ชื่อ-นามสกุล (ไทย)
		{
			X:          0.20,
			Y:          0.35,
			Width:      0.50,
			Height:     0.08,
			Confidence: 0.90,
			Type:       "name_thai",
		},
		// ชื่อ-นามสกุล (อังกฤษ)
		{
			X:          0.20,
			Y:          0.44,
			Width:      0.50,
			Height:     0.06,
			Confidence: 0.90,
			Type:       "name_eng",
		},
		// วันเกิด
		{
			X:          0.20,
			Y:          0.52,
			Width:      0.35,
			Height:     0.06,
			Confidence: 0.85,
			Type:       "date_of_birth",
		},
		// รูปภาพ
		{
			X:          0.75,
			Y:          0.30,
			Width:      0.20,
			Height:     0.35,
			Confidence: 0.95,
			Type:       "photo",
		},
		// ที่อยู่
		{
			X:          0.20,
			Y:          0.60,
			Width:      0.50,
			Height:     0.20,
			Confidence: 0.80,
			Type:       "address",
		},
		// วันออกบัตร
		{
			X:          0.20,
			Y:          0.82,
			Width:      0.25,
			Height:     0.05,
			Confidence: 0.85,
			Type:       "issue_date",
		},
		// วันหมดอายุ
		{
			X:          0.50,
			Y:          0.82,
			Width:      0.25,
			Height:     0.05,
			Confidence: 0.85,
			Type:       "expire_date",
		},
	}

	return regions, nil
}

// CropRegion ตัดภาพตาม region
func (d *DefaultRegionDetector) CropRegion(ctx context.Context, imageData []byte, region *Region) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}

	bounds := img.Bounds()
	width := bounds.Dx()
	height := bounds.Dy()

	// แปลง % เป็น pixels
	x1 := int(region.X * float64(width))
	y1 := int(region.Y * float64(height))
	x2 := int((region.X + region.Width) * float64(width))
	y2 := int((region.Y + region.Height) * float64(height))

	// ตรวจสอบขอบเขต
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

	// สร้างภาพที่ crop แล้ว
	cropped := image.NewRGBA(image.Rect(0, 0, x2-x1, y2-y1))
	for y := y1; y < y2; y++ {
		for x := x1; x < x2; x++ {
			cropped.Set(x-x1, y-y1, img.At(x, y))
		}
	}

	// Encode เป็น bytes
	buf := new(bytes.Buffer)
	err = png.Encode(buf, cropped)
	if err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}