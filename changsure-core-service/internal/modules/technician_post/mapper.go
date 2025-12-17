package technicianposts

import (
	"context"
	"time"

	"changsure-core-service/pkg/storage"
)

func ToPostResponse(post *TechnicianPost) *TechnicianPostResponse {
	if post == nil {
		return nil
	}

	resp := &TechnicianPostResponse{
		ID:           post.ID,
		TechnicianID: post.TechnicianID,
		Title:        post.Title,
		Description:  post.Description,
		ServiceID:    post.ServiceID,
		ProvinceID:   post.ProvinceID,
		IsPublished:  post.IsPublished,
		CreatedAt:    post.CreatedAt.Unix(),
	}

	if post.Service != nil {
		resp.ServiceName = &post.Service.SerName

		if post.Service.Category != nil {
			cid := post.Service.Category.ID
			resp.CategoryID = &cid

			cname := post.Service.Category.CatName
			resp.CategoryName = &cname
		}
	}

	if post.Province != nil {
		resp.ProvinceName = &post.Province.NameTH
	}

	resp.Images = make([]TechnicianPostImageResponse, 0)

	for _, img := range post.Images {
		url := img.ImageURL
		finalURL := url

		if storage.GlobalMinio != nil && url != "" {

			ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)

			presigned, err := storage.GlobalMinio.PresignGet(ctx, url, time.Hour, false)
			if err == nil {
				finalURL = presigned
			}
			cancel()
		}

		resp.Images = append(resp.Images, TechnicianPostImageResponse{
			ID:       img.ID,
			ImageURL: finalURL,
			Order:    img.SortOrder,
		})
	}

	return resp
}
