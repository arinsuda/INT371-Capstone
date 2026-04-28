package service

import (
	"changsure-core-service/pkg/storage"
	"context"
	"time"
)

func MapServiceToResponse(m *Service) ServiceResponse {
	resp := ServiceResponse{
		ID:              m.ID,
		SerName:         m.SerName,
		SerDescription:  m.SerDescription,
		SerDetails:      m.SerDetails,
		AdditionalTerms: m.AdditionalTerms,
		WorkingDuration: m.WorkingDuration,
		DefaultPrice:    m.DefaultPrice,
		IsActive:        m.IsActive,
		CategoryID:      m.CategoryID,
		CreatedAt:       m.CreatedAt.Format(time.RFC3339),
		UpdatedAt:       m.UpdatedAt.Format(time.RFC3339),
	}

	if m.Category != nil {
		resp.CategoryName = &m.Category.CatName
	}

	imgs := make([]string, 0, len(m.ImageURLs))
	for _, key := range m.ImageURLs {
		if key == "" {
			continue
		}

		url, err := storage.GlobalMinio.PresignGet(
			context.Background(),
			key,
			time.Hour,
			false,
		)
		if err != nil {

			imgs = append(imgs, key)
			continue
		}

		imgs = append(imgs, url)
	}

	resp.ImageURLs = imgs

	return resp
}

// build price จาก technician data หรือ fallback default
func buildMenuPrice(svc *Service, techData *PriceAndCount) (MenuPrice, string, int) {
	if techData != nil && techData.TechnicianCount > 0 {
		p := MenuPrice{
			Type: "range",
			Min:  techData.MinPrice,
		}
		if techData.MaxPrice > techData.MinPrice {
			p.Max = &techData.MaxPrice
		} else {
			p.Type = "fixed"
		}
		return p, "technician", techData.TechnicianCount
	}

	// fallback: parse default_price
	return parseDefaultPrice(svc.DefaultPrice), "default", 0
}

func parseDefaultPrice(dp map[string]interface{}) MenuPrice {
	if dp == nil {
		return MenuPrice{Type: "fixed", Min: 0}
	}
	toFloat := func(v interface{}) float64 {
		switch n := v.(type) {
		case float64:
			return n
		case int:
			return float64(n)
		}
		return 0
	}
	switch dp["type"] {
	case "fixed":
		return MenuPrice{Type: "fixed", Min: toFloat(dp["value"])}
	case "range":
		min := toFloat(dp["min"])
		p := MenuPrice{Type: "range", Min: min}
		if maxVal, ok := dp["max"]; ok {
			if m := toFloat(maxVal); m > min {
				p.Max = &m
			}
		}
		return p
	default:
		return MenuPrice{Type: "range", Min: toFloat(dp["min"])}
	}
}

func MapToServiceMenuCard(m *Service, techData *PriceAndCount, presignFn func(string) string) ServiceMenuCard {
	price, source, count := buildMenuPrice(m, techData)

	var thumbnail *string
	if len(m.ImageURLs) > 0 && m.ImageURLs[0] != "" {
		u := presignFn(m.ImageURLs[0])
		thumbnail = &u
	}

	return ServiceMenuCard{
		ID:              m.ID,
		SerName:         m.SerName,
		ThumbnailURL:    thumbnail,
		Price:           price,
		PriceSource:     source,
		TechnicianCount: count,
		Available:       count > 0,
	}
}

func MapToServiceMenuDetail(m *Service, techData *PriceAndCount, presignFn func(string) string) ServiceMenuDetail {
	price, source, count := buildMenuPrice(m, techData)

	imgs := make([]string, 0, len(m.ImageURLs))
	for _, key := range m.ImageURLs {
		if key != "" {
			imgs = append(imgs, presignFn(key))
		}
	}

	detail := ServiceMenuDetail{
		ID:              m.ID,
		SerName:         m.SerName,
		SerDescription:  m.SerDescription,
		SerDetails:      m.SerDetails,
		AdditionalTerms: m.AdditionalTerms,
		WorkingDuration: m.WorkingDuration,
		ImageURLs:       imgs,
		Price:           price,
		PriceSource:     source,
		TechnicianCount: count,
		Available:       count > 0,
		CategoryID:      m.CategoryID,
	}
	if m.Category != nil {
		detail.CategoryName = &m.Category.CatName
	}
	return detail
}
