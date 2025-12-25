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
		// เพิ่มตรงนี้: ดึง ID จาก field ใหม่โดยตรง
		CategoryID:  post.ServiceCategoryID,
		IsPublished: post.IsPublished,
		CreatedAt:   post.CreatedAt.Unix(),
	}

	// 1. Map Service Name (ถ้ามี Service)
	if post.Service != nil {
		resp.ServiceName = &post.Service.SerName
	}

	// 2. Map Category Name (แก้ไขใหม่: ดึงจาก ServiceCategory โดยตรง)
	if post.Category != nil {
		// ใช้ CatName ตามโครงสร้างเดิมที่คุณเคยใช้
		cname := post.Category.CatName
		resp.CategoryName = &cname
	}

	// 3. Map Province Name
	if post.Province != nil {
		resp.ProvinceName = &post.Province.NameTH
	}

	// 4. จัดการ Images (คงเดิม)
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
