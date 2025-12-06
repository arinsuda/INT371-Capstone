package technicianposts

import (
	"context"
	"time"

	"changsure-core-service/pkg/storage"
)

func mapToResponse(p *TechnicianPost) TechnicianPostResponse {
	var (
		sid   *uint
		sname *string
		pid   *uint
		pname *string
	)

	if p.ServiceID != nil {
		sid = p.ServiceID
	}
	if p.Service != nil {
		nn := p.Service.SerName
		sname = &nn
	}
	if p.ProvinceID != nil {
		pid = p.ProvinceID
	}
	if p.Province != nil {
		nn := p.Province.NameTH
		pname = &nn
	}

	imgs := make([]TechnicianPostImageResponse, 0, len(p.Images))

	for _, im := range p.Images {
		url := ""

		if im.ImageURL != "" && storage.GlobalMinio != nil {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			presigned, err := storage.GlobalMinio.PresignGet(ctx, im.ImageURL, time.Hour, false)
			if err == nil {
				url = presigned
			}
		}

		imgs = append(imgs, TechnicianPostImageResponse{
			ID:       im.ID,
			ImageURL: url,
			Order:    im.SortOrder,
		})
	}

	return TechnicianPostResponse{
		ID:           p.ID,
		TechnicianID: p.TechnicianID,
		Title:        p.Title,
		Description:  p.Description,
		ServiceID:    sid,
		ServiceName:  sname,
		ProvinceID:   pid,
		ProvinceName: pname,
		PostDate:     p.PostDate,
		Images:       imgs,
		IsPublished:  p.IsPublished,
		CreatedAt:    p.CreatedAt.Unix(),
	}
}
