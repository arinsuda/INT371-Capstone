package provider

import (
	"bytes"
	"context"
	"errors"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"math"
)

type DefaultImageProcessor struct{}

func NewDefaultImageProcessor() ImageProcessor {
	return &DefaultImageProcessor{}
}

func (p *DefaultImageProcessor) Preprocess(ctx context.Context, imageData []byte, opts *PreprocessOptions) ([]byte, error) {
	if opts == nil {
		return imageData, nil
	}

	if !(opts.Grayscale || opts.Normalize || opts.EnhanceContrast || (opts.Upscale > 1.0) || opts.AutoRotate) {
		return imageData, nil
	}

	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}

	if err := ctxErr(ctx); err != nil {
		return nil, err
	}

	if opts.AutoRotate {

	}

	var g *image.Gray
	if opts.Grayscale || opts.Normalize || opts.EnhanceContrast {
		if err := ctxErr(ctx); err != nil {
			return nil, err
		}
		g = toGray(img)
		img = g
	}

	if opts.EnhanceContrast && g != nil {
		if err := ctxErr(ctx); err != nil {
			return nil, err
		}
		g = sharpenImage(g)
		img = g
	}

	if opts.Normalize && g != nil {
		if err := ctxErr(ctx); err != nil {
			return nil, err
		}
		g = normalizeMinMax(g)
		img = g
	}

	if opts.EnhanceContrast && g != nil {
		if err := ctxErr(ctx); err != nil {
			return nil, err
		}
		g = histogramEqualization(g)
		img = g
	}

	if opts.Upscale > 1.0 {
		if err := ctxErr(ctx); err != nil {
			return nil, err
		}
		const maxSide = 8192
		b := img.Bounds()
		newW := int(float64(b.Dx()) * opts.Upscale)
		newH := int(float64(b.Dy()) * opts.Upscale)
		if newW > maxSide || newH > maxSide {
			scale := math.Min(float64(maxSide)/float64(b.Dx()), float64(maxSide)/float64(b.Dy()))
			if scale < 1.0 {
				scale = 1.0
			}
			newW = int(float64(b.Dx()) * scale)
			newH = int(float64(b.Dy()) * scale)
		}
		img = bilinearResize(img, newW, newH)
	}

	return encodePNG(img)
}

func (p *DefaultImageProcessor) Normalize(ctx context.Context, imageData []byte) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}
	if err := ctxErr(ctx); err != nil {
		return nil, err
	}
	g := toGray(img)
	g = normalizeMinMax(g)
	return encodePNG(g)
}

func (p *DefaultImageProcessor) Upscale(ctx context.Context, imageData []byte, scale float64) ([]byte, error) {
	if scale <= 1.0 {
		return imageData, nil
	}
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}
	if err := ctxErr(ctx); err != nil {
		return nil, err
	}
	b := img.Bounds()
	newW := int(float64(b.Dx()) * scale)
	newH := int(float64(b.Dy()) * scale)
	img = bilinearResize(img, newW, newH)
	return encodePNG(img)
}

func (p *DefaultImageProcessor) AutoRotate(ctx context.Context, imageData []byte) ([]byte, float64, error) {

	return imageData, 0.0, nil
}

func (p *DefaultImageProcessor) ConvertToGrayscale(ctx context.Context, imageData []byte) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}
	if err := ctxErr(ctx); err != nil {
		return nil, err
	}
	g := toGray(img)
	return encodePNG(g)
}

func (p *DefaultImageProcessor) EnhanceContrast(ctx context.Context, imageData []byte) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}
	if err := ctxErr(ctx); err != nil {
		return nil, err
	}
	g := toGray(img)

	g = sharpenImage(g)
	g = histogramEqualization(g)

	return encodePNG(g)
}

func ctxErr(ctx context.Context) error {
	if ctx == nil {
		return nil
	}
	select {
	case <-ctx.Done():
		if ctx.Err() != nil {
			return ctx.Err()
		}
	default:
	}
	return nil
}

func toGray(src image.Image) *image.Gray {
	if g, ok := src.(*image.Gray); ok {
		b := g.Bounds()
		dst := image.NewGray(b)
		draw.Draw(dst, b, g, b.Min, draw.Src)
		return dst
	}
	b := src.Bounds()
	dst := image.NewGray(b)

	for y := b.Min.Y; y < b.Max.Y; y++ {
		for x := b.Min.X; x < b.Max.X; x++ {
			r, g, bl, _ := src.At(x, y).RGBA()
			yr := 0.299*float64(r) + 0.587*float64(g) + 0.114*float64(bl)
			dst.SetGray(x, y, color.Gray{Y: uint8(yr / 257.0)})
		}
	}
	return dst
}

func normalizeMinMax(g *image.Gray) *image.Gray {
	b := g.Bounds()
	var minV, maxV uint8 = 255, 0
	for y := b.Min.Y; y < b.Max.Y; y++ {
		i := g.PixOffset(b.Min.X, y)
		row := g.Pix[i : i+(b.Dx())]
		for _, v := range row {
			if v < minV {
				minV = v
			}
			if v > maxV {
				maxV = v
			}
		}
	}
	if maxV <= minV {
		return g
	}
	dst := image.NewGray(b)
	scale := 255.0 / float64(int(maxV)-int(minV))
	for y := b.Min.Y; y < b.Max.Y; y++ {
		srcI := g.PixOffset(b.Min.X, y)
		dstI := dst.PixOffset(b.Min.X, y)
		srcRow := g.Pix[srcI : srcI+(b.Dx())]
		dstRow := dst.Pix[dstI : dstI+(b.Dx())]
		for x := 0; x < len(srcRow); x++ {
			dstRow[x] = uint8(float64(int(srcRow[x])-int(minV))*scale + 0.5)
		}
	}
	return dst
}

func histogramEqualization(g *image.Gray) *image.Gray {
	b := g.Bounds()
	hist := [256]int{}
	total := (b.Dx()) * (b.Dy())

	for y := b.Min.Y; y < b.Max.Y; y++ {
		i := g.PixOffset(b.Min.X, y)
		row := g.Pix[i : i+(b.Dx())]
		for _, v := range row {
			hist[int(v)]++
		}
	}

	cdf := [256]int{}
	sum := 0
	for i := 0; i < 256; i++ {
		sum += hist[i]
		cdf[i] = sum
	}

	cdfMin := 0
	for i := 0; i < 256; i++ {
		if cdf[i] > 0 {
			cdfMin = cdf[i]
			break
		}
	}
	if total <= 0 || cdfMin == 0 {
		return g
	}

	dst := image.NewGray(b)
	den := float64(total - cdfMin)
	if den <= 0 {
		return g
	}
	for y := b.Min.Y; y < b.Max.Y; y++ {
		si := g.PixOffset(b.Min.X, y)
		di := dst.PixOffset(b.Min.X, y)
		sr := g.Pix[si : si+(b.Dx())]
		dr := dst.Pix[di : di+(b.Dx())]
		for x := 0; x < len(sr); x++ {
			v := int(sr[x])
			eq := float64(cdf[v]-cdfMin) / den
			if eq < 0 {
				eq = 0
			}
			if eq > 1 {
				eq = 1
			}
			dr[x] = uint8(eq*255.0 + 0.5)
		}
	}
	return dst
}

func sharpenImage(g *image.Gray) *image.Gray {
	b := g.Bounds()
	w, h := b.Dx(), b.Dy()

	blurred := image.NewGray(b)

	for y := 1; y < h-1; y++ {
		for x := 1; x < w-1; x++ {
			sum := 0
			for dy := -1; dy <= 1; dy++ {
				for dx := -1; dx <= 1; dx++ {
					sum += int(g.GrayAt(b.Min.X+x+dx, b.Min.Y+y+dy).Y)
				}
			}
			blurred.SetGray(b.Min.X+x, b.Min.Y+y, color.Gray{Y: uint8(sum / 9)})
		}
	}

	amount := 1.5
	dst := image.NewGray(b)

	for y := b.Min.Y; y < b.Max.Y; y++ {
		for x := b.Min.X; x < b.Max.X; x++ {
			original := float64(g.GrayAt(x, y).Y)
			blur := float64(blurred.GrayAt(x, y).Y)

			sharp := original + amount*(original-blur)

			if sharp < 0 {
				sharp = 0
			}
			if sharp > 255 {
				sharp = 255
			}

			dst.SetGray(x, y, color.Gray{Y: uint8(sharp)})
		}
	}

	return dst
}

func bilinearResize(src image.Image, newW, newH int) *image.RGBA {
	if newW <= 0 || newH <= 0 {
		panic(errors.New("bilinearResize: invalid target size"))
	}
	b := src.Bounds()
	srcW := b.Dx()
	srcH := b.Dy()

	if srcW == newW && srcH == newH {
		dst := image.NewRGBA(b.Sub(b.Min))
		draw.Draw(dst, dst.Bounds(), src, b.Min, draw.Src)
		return dst
	}

	dst := image.NewRGBA(image.Rect(0, 0, newW, newH))
	scaleX := float64(srcW-1) / float64(newW-1)
	scaleY := float64(srcH-1) / float64(newH-1)

	for y := 0; y < newH; y++ {
		fy := scaleY * float64(y)
		y0 := int(fy)
		y1 := int(math.Min(float64(y0+1), float64(srcH-1)))
		wy := fy - float64(y0)

		for x := 0; x < newW; x++ {
			fx := scaleX * float64(x)
			x0 := int(fx)
			x1 := int(math.Min(float64(x0+1), float64(srcW-1)))
			wx := fx - float64(x0)

			c00 := colorRGBA(src.At(b.Min.X+x0, b.Min.Y+y0))
			c10 := colorRGBA(src.At(b.Min.X+x1, b.Min.Y+y0))
			c01 := colorRGBA(src.At(b.Min.X+x0, b.Min.Y+y1))
			c11 := colorRGBA(src.At(b.Min.X+x1, b.Min.Y+y1))

			r := lerp(lerp(float64(c00.R), float64(c10.R), wx), lerp(float64(c01.R), float64(c11.R), wx), wy)
			g := lerp(lerp(float64(c00.G), float64(c10.G), wx), lerp(float64(c01.G), float64(c11.G), wx), wy)
			bl := lerp(lerp(float64(c00.B), float64(c10.B), wx), lerp(float64(c01.B), float64(c11.B), wx), wy)
			a := lerp(lerp(float64(c00.A), float64(c10.A), wx), lerp(float64(c01.A), float64(c11.A), wx), wy)

			dst.SetRGBA(x, y, color.RGBA{uint8(r + 0.5), uint8(g + 0.5), uint8(bl + 0.5), uint8(a + 0.5)})
		}
	}
	return dst
}

func colorRGBA(c color.Color) color.RGBA {
	R, G, B, A := c.RGBA()
	return color.RGBA{uint8(R >> 8), uint8(G >> 8), uint8(B >> 8), uint8(A >> 8)}
}

func lerp(a, b, t float64) float64 { return a + (b-a)*t }

func encodePNG(img image.Image) ([]byte, error) {
	buf := new(bytes.Buffer)
	if err := png.Encode(buf, img); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}
