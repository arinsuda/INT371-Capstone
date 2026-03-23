package technicianposts

import (
	"context"
	"fmt"
	"log/slog"
	"mime/multipart"
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/modules/notification"
	"changsure-core-service/pkg/storage"

	"gorm.io/gorm"
)

type Service interface {
	Create(ctx context.Context, techID uint, req CreateTechnicianPostDTO) (*TechnicianPostResponse, error)
	Update(ctx context.Context, techID, postID uint, req UpdateTechnicianPostDTO) (*TechnicianPostResponse, error)
	Delete(ctx context.Context, techID, postID uint, hard bool) error
	Get(ctx context.Context, techID, postID uint) (*TechnicianPostResponse, error)
	List(ctx context.Context, techID uint, q ListTechnicianPostsQuery) (*PostListResponse, error)
	ListPublicPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery) (*PostListResponse, error)
	GetPublic(ctx context.Context, techID, postID uint) (*TechnicianPostResponse, error)

	// Report
	ReportPost(ctx context.Context, techID, postID, adminID uint, req CreatePostReportDTO) (*PostReportResponse, error)
	ListReports(ctx context.Context, techID uint, q ListPostReportsQuery, isAdmin bool) (*PostReportListResponse, error)
}

type service struct {
	repo    Repository
	storage storage.Storage
	mapper  *Mapper
	notif   notification.Service
}

func NewService(repo Repository, s storage.Storage, notif notification.Service) Service {
	return &service{
		repo:    repo,
		storage: s,
		mapper:  NewMapper(s),
		notif:   notif,
	}
}

func (s *service) Get(ctx context.Context, techID, postID uint) (*TechnicianPostResponse, error) {
	post, err := s.repo.GetPost(ctx, postID, techID)
	if err != nil {
		return nil, appErrors.NewNotFound("post not found")
	}
	return s.mapper.ToPostResponse(post), nil
}

func (s *service) List(ctx context.Context, techID uint, q ListTechnicianPostsQuery) (*PostListResponse, error) {
	q.SetDefaults()
	posts, total, err := s.repo.ListPosts(ctx, techID, q)
	if err != nil {
		return nil, fmt.Errorf("list posts: %w", err)
	}
	return s.toListResponse(posts, total, q), nil
}

func (s *service) ListPublicPosts(ctx context.Context, techID uint, q ListTechnicianPostsQuery) (*PostListResponse, error) {
	q.SetDefaults()
	posts, total, err := s.repo.ListPublicPosts(ctx, techID, q)
	if err != nil {
		return nil, fmt.Errorf("list public posts: %w", err)
	}
	return s.toListResponse(posts, total, q), nil
}

func (s *service) GetPublic(ctx context.Context, techID, postID uint) (*TechnicianPostResponse, error) {
	post, err := s.repo.GetPublicPost(ctx, postID, techID)
	if err != nil {
		return nil, appErrors.NewNotFound("post not found")
	}
	return s.mapper.ToPostResponse(post), nil
}

func (s *service) Create(ctx context.Context, techID uint, req CreateTechnicianPostDTO) (*TechnicianPostResponse, error) {
	post := &TechnicianPost{
		TechnicianID:      techID,
		Title:             req.Title,
		Description:       req.Description,
		ServiceCategoryID: req.ServiceCategoryID,
		IsPublished:       true,
	}
	if err := s.repo.CreatePost(ctx, post); err != nil {
		return nil, fmt.Errorf("create post: %w", err)
	}
	if len(req.Images) > 0 {
		imgs, err := s.uploadImages(ctx, post.ID, req.Images)
		if err != nil {
			return nil, err
		}
		if err := s.repo.AddPostImages(ctx, imgs); err != nil {
			return nil, fmt.Errorf("save images: %w", err)
		}
	}
	full, err := s.repo.GetPost(ctx, post.ID, techID)
	if err != nil {
		return nil, fmt.Errorf("reload post: %w", err)
	}
	return s.mapper.ToPostResponse(full), nil
}

func (s *service) Update(ctx context.Context, techID, postID uint, req UpdateTechnicianPostDTO) (*TechnicianPostResponse, error) {
	if _, err := s.repo.GetPost(ctx, postID, techID); err != nil {
		return nil, appErrors.NewNotFound("post not found")
	}

	var newImages []TechnicianPostImage
	if len(req.NewImages) > 0 {
		uploadCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
		defer cancel()
		imgs, err := s.uploadImages(uploadCtx, postID, req.NewImages)
		if err != nil {
			return nil, err
		}
		newImages = imgs
	}

	err := s.repo.DB().WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		updateData := buildUpdateMap(req)
		if len(updateData) > 0 {
			if err := tx.Model(&TechnicianPost{}).
				Where("id = ? AND technician_id = ?", postID, techID).
				Updates(updateData).Error; err != nil {
				return fmt.Errorf("update post fields: %w", err)
			}
		}
		if len(req.ImageIDsToDelete) > 0 {
			if err := tx.Where("post_id = ? AND id IN ?", postID, req.ImageIDsToDelete).
				Delete(&TechnicianPostImage{}).Error; err != nil {
				return fmt.Errorf("delete images: %w", err)
			}
		}
		if len(newImages) > 0 {
			if err := tx.Create(&newImages).Error; err != nil {
				return fmt.Errorf("insert images: %w", err)
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	full, err := s.repo.GetPost(ctx, postID, techID)
	if err != nil {
		return nil, fmt.Errorf("reload post: %w", err)
	}
	return s.mapper.ToPostResponse(full), nil
}

func (s *service) Delete(ctx context.Context, techID, postID uint, hard bool) error {
	if hard {
		return s.repo.HardDeletePost(ctx, postID, techID)
	}
	return s.repo.SoftDeletePost(ctx, postID, techID)
}

// --- Report ---

func (s *service) ReportPost(ctx context.Context, techID, postID, adminID uint, req CreatePostReportDTO) (*PostReportResponse, error) {
	post, err := s.repo.GetPost(ctx, postID, techID)
	if err != nil {
		return nil, appErrors.NewNotFound("post not found")
	}

	// นับจำนวน WARNING ที่มีอยู่แล้ว (เฉพาะ WARNING ไม่นับ BLACKLIST)
	warningCount, err := s.repo.CountWarningsByTechnician(ctx, techID)
	if err != nil {
		return nil, fmt.Errorf("count warnings: %w", err)
	}

	// WARNING ใหม่นี้จะเป็นครั้งที่เท่าไหร่
	newWarningCount := warningCount + 1

	// ถ้าครบ 3 ครั้ง → บังคับ ban โดยไม่สนว่า Admin เลือก severity อะไร
	shouldBan := newWarningCount >= 3

	report := &TechnicianPostReport{
		PostID:       postID,
		TechnicianID: techID,
		AdminID:      adminID,
		ReportType:   req.ReportType,
		Reason:       req.Reason,
		Severity:     req.Severity,
		DeletePost:   req.DeletePost,
	}

	err = s.repo.DB().WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(report).Error; err != nil {
			return fmt.Errorf("create report: %w", err)
		}

		// ลบผลงานถ้าเลือก delete_post
		if req.DeletePost {
			if err := tx.Where("id = ? AND technician_id = ?", postID, techID).
				Delete(&TechnicianPost{}).Error; err != nil {
				return fmt.Errorf("delete post: %w", err)
			}
		}

		// Ban เมื่อ WARNING ครบ 3 ครั้ง หรือ Admin เลือก BLACKLIST เอง
		if shouldBan || req.Severity == ReportSeverityBlacklist {
			if err := tx.Table("technicians").
				Where("id = ?", techID).
				Update("is_available", false).Error; err != nil {
				return fmt.Errorf("ban technician: %w", err)
			}
		}

		return nil
	})
	if err != nil {
		return nil, err
	}

	// ส่ง notification แจ้งช่างหลัง transaction สำเร็จ
	if s.notif != nil {
		go s.sendReportNotification(context.Background(), techID, postID, post.Title, req, newWarningCount, shouldBan)
	}

	return toReportResponse(report, ""), nil
}

func (s *service) sendReportNotification(
	ctx context.Context,
	techID, postID uint,
	postTitle string,
	req CreatePostReportDTO,
	warningCount int64,
	banned bool,
) {
	var title, message, notifType string

	switch {
	case banned:
		notifType = "POST_BANNED"
		title = "บัญชีของคุณถูกระงับการใช้งาน 🚫"
		message = fmt.Sprintf(
			"ผลงาน \"%s\" ถูกรายงาน และบัญชีของคุณถูกระงับการใช้งานเนื่องจากได้รับการตักเตือนครบ 3 ครั้ง กรุณาติดต่อทีมงาน",
			postTitle,
		)

	case req.Severity == ReportSeverityWarning:
		notifType = "POST_WARNING"
		title = fmt.Sprintf("คำเตือนครั้งที่ %d ⚠️", warningCount)
		message = fmt.Sprintf(
			"ผลงาน \"%s\" ถูกรายงานในประเภท: %s (คำเตือน %d/3 ครั้ง หากครบ 3 ครั้งบัญชีจะถูกระงับ)",
			postTitle, req.ReportType, warningCount,
		)

	default:
		// BLACKLIST โดย Admin โดยตรง
		notifType = "POST_BLACKLISTED"
		title = "บัญชีของคุณถูกระงับการใช้งาน 🚫"
		message = fmt.Sprintf(
			"ผลงาน \"%s\" ถูกรายงานประเภท: %s และบัญชีของคุณถูกระงับการใช้งาน กรุณาติดต่อทีมงาน",
			postTitle, req.ReportType,
		)
	}

	_, err := s.notif.Create(ctx, notification.CreateNotificationInput{
		RecipientRole: notification.RoleTechnician,
		RecipientID:   techID,
		Type:          notifType,
		Title:         title,
		Message:       message,
		EntityType:    "post",
		EntityID:      postID,
		Data: map[string]any{
			"post_id":       postID,
			"report_type":   req.ReportType,
			"severity":      req.Severity,
			"warning_count": warningCount,
			"banned":        banned,
		},
	})
	if err != nil {
		slog.Warn("failed to send report notification",
			"technician_id", techID,
			"post_id", postID,
			"error", err,
		)
	}
}

func (s *service) ListReports(ctx context.Context, techID uint, q ListPostReportsQuery, isAdmin bool) (*PostReportListResponse, error) {
	q.SetDefaults()

	reports, total, err := s.repo.ListReportsByTechnician(ctx, techID, q)
	if err != nil {
		return nil, fmt.Errorf("list reports: %w", err)
	}

	items := make([]PostReportResponse, 0, len(reports))
	for i := range reports {
		adminName := ""
		if reports[i].Admin != nil {
			adminName = reports[i].Admin.FirstName + " " + reports[i].Admin.LastName
		}
		resp := toReportResponse(&reports[i], adminName)

		// ช่างดูได้แต่ไม่เห็น admin_id และ admin_name
		if !isAdmin {
			resp.AdminID = 0
			resp.AdminName = ""
		}
		items = append(items, *resp)
	}

	return &PostReportListResponse{
		Items:   items,
		Total:   total,
		Page:    q.Page,
		PerPage: q.PerPage,
	}, nil
}

func toReportResponse(r *TechnicianPostReport, adminName string) *PostReportResponse {
	return &PostReportResponse{
		ID:           r.ID,
		PostID:       r.PostID,
		TechnicianID: r.TechnicianID,
		ReportType:   r.ReportType,
		Reason:       r.Reason,
		Severity:     r.Severity,
		DeletePost:   r.DeletePost,
		AdminID:      r.AdminID,
		AdminName:    adminName,
		ReportedAt:   r.CreatedAt.Unix(),
	}
}

const (
	maxUploadRetries = 3
	retryBaseDelay   = 200 * time.Millisecond
)

func (s *service) uploadImages(ctx context.Context, postID uint, files []*multipart.FileHeader) ([]TechnicianPostImage, error) {
	images := make([]TechnicianPostImage, 0, len(files))
	for i, file := range files {
		key, err := s.uploadWithRetry(ctx, postID, file, maxUploadRetries)
		if err != nil {
			return nil, err
		}
		images = append(images, TechnicianPostImage{PostID: postID, ImageURL: key, SortOrder: i})
	}
	return images, nil
}

func (s *service) uploadWithRetry(ctx context.Context, postID uint, file *multipart.FileHeader, maxRetry int) (string, error) {
	var lastErr error
	for attempt := 1; attempt <= maxRetry; attempt++ {
		src, err := file.Open()
		if err != nil {
			return "", fmt.Errorf("open file %q: %w", file.Filename, err)
		}
		filename := fmt.Sprintf("%d_%d_%s", postID, time.Now().UnixNano(), file.Filename)
		key, err := s.storage.UploadFile(ctx, src, filename, fmt.Sprintf("posts/%d", postID), file.Size, file.Header.Get("Content-Type"))
		src.Close()
		if err == nil {
			return key, nil
		}
		lastErr = err
		slog.Warn("upload attempt failed", "attempt", attempt, "max", maxRetry, "file", file.Filename, "error", err)
		time.Sleep(time.Duration(attempt) * retryBaseDelay)
	}
	return "", fmt.Errorf("upload %q failed after %d retries: %w", file.Filename, maxRetry, lastErr)
}

func buildUpdateMap(req UpdateTechnicianPostDTO) map[string]any {
	data := make(map[string]any)
	if req.Title != nil {
		data["title"] = *req.Title
	}
	if req.Description != nil {
		data["description"] = *req.Description
	}
	if req.ServiceCategoryID != nil {
		data["service_category_id"] = *req.ServiceCategoryID
	}
	if req.IsPublished != nil {
		data["is_published"] = *req.IsPublished
	}
	return data
}

func (s *service) toListResponse(posts []TechnicianPost, total int64, q ListTechnicianPostsQuery) *PostListResponse {
	items := make([]TechnicianPostResponse, 0, len(posts))
	for i := range posts {
		items = append(items, *s.mapper.ToPostResponse(&posts[i]))
	}
	return &PostListResponse{Items: items, Total: total, Page: q.Page, PerPage: q.PerPage}
}
