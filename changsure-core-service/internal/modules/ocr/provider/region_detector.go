package provider

import (
	"bytes"
	"context"
	"image"
	"image/png"
	"os"
	"strconv"
)

func NewDefaultRegionDetector() RegionDetector {
	const (
		defIDx    = 0.25
		defIDy    = 0.15
		defIDw    = 0.50
		defIDh    = 0.08
		defIDConf = 0.90

		defNamex    = 0.25
		defNamey    = 0.25
		defNamew    = 0.50
		defNameh    = 0.10
		defNameConf = 0.80
	)

	d := &DefaultRegionDetector{
		idX:          getEnvFloat("OCR_ID_CROP_X", defIDx),
		idY:          getEnvFloat("OCR_ID_CROP_Y", defIDy),
		idW:          getEnvFloat("OCR_ID_CROP_W", defIDw),
		idH:          getEnvFloat("OCR_ID_CROP_H", defIDh),
		idConfidence: getEnvFloat("OCR_ID_REGION_CONF", defIDConf),

		nameX:          getEnvFloat("OCR_NAME_CROP_X", defNamex),
		nameY:          getEnvFloat("OCR_NAME_CROP_Y", defNamey),
		nameW:          getEnvFloat("OCR_NAME_CROP_W", defNamew),
		nameH:          getEnvFloat("OCR_NAME_CROP_H", defNameh),
		nameConfidence: getEnvFloat("OCR_NAME_REGION_CONF", defNameConf),
	}

	d.idX, d.idY, d.idW, d.idH = clampBox01(d.idX, d.idY, d.idW, d.idH)
	d.nameX, d.nameY, d.nameW, d.nameH = clampBox01(d.nameX, d.nameY, d.nameW, d.nameH)

	return d
}

func (r *DefaultRegionDetector) DetectIDNumberRegion(ctx context.Context, imageData []byte) (*Region, error) {
	return &Region{
		X:          r.idX,
		Y:          r.idY,
		Width:      r.idW,
		Height:     r.idH,
		Confidence: r.idConfidence,
		Type:       "id_number",
	}, nil
}

func (r *DefaultRegionDetector) DetectNameRegion(ctx context.Context, imageData []byte) (*Region, error) {
	return &Region{
		X:          r.nameX,
		Y:          r.nameY,
		Width:      r.nameW,
		Height:     r.nameH,
		Confidence: r.nameConfidence,
		Type:       "name",
	}, nil
}

func (r *DefaultRegionDetector) DetectAllRegions(ctx context.Context, imageData []byte) ([]*Region, error) {
	var regions []*Region

	if idRegion, err := r.DetectIDNumberRegion(ctx, imageData); err == nil {
		regions = append(regions, idRegion)
	}

	if nameRegion, err := r.DetectNameRegion(ctx, imageData); err == nil {
		regions = append(regions, nameRegion)
	}

	return regions, nil
}

func (r *DefaultRegionDetector) CropRegion(ctx context.Context, imageData []byte, region *Region) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}

	bounds := img.Bounds()
	width := bounds.Dx()
	height := bounds.Dy()

	x1 := int(region.X * float64(width))
	y1 := int(region.Y * float64(height))
	x2 := int((region.X + region.Width) * float64(width))
	y2 := int((region.Y + region.Height) * float64(height))

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

	cropped := image.NewRGBA(image.Rect(0, 0, x2-x1, y2-y1))
	for y := y1; y < y2; y++ {
		for x := x1; x < x2; x++ {
			cropped.Set(x-x1, y-y1, img.At(x, y))
		}
	}

	buf := new(bytes.Buffer)
	if err := png.Encode(buf, cropped); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func getEnvFloat(key string, def float64) float64 {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	f, err := strconv.ParseFloat(v, 64)
	if err != nil {
		return def
	}
	return f
}

func clamp01(v float64) float64 {
	if v < 0 {
		return 0
	}
	if v > 1 {
		return 1
	}
	return v
}

func clampBox01(x, y, w, h float64) (float64, float64, float64, float64) {
	x = clamp01(x)
	y = clamp01(y)
	w = clamp01(w)
	h = clamp01(h)

	if x+w > 1 {
		w = 1 - x
	}
	if y+h > 1 {
		h = 1 - y
	}
	return x, y, w, h
}
