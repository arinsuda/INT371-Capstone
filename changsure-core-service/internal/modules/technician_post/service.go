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

func (s *service) ReportPost(ctx context.Context, techID, postID, adminID uint, req CreatePostReportDTO) (*PostReportResponse, error) {
	post, err := s.repo.GetPost(ctx, postID, techID)
	if err != nil {
		return nil, appErrors.NewNotFound("post not found")
	}

	exists, err := s.repo.ExistsReportByAdminAndPost(ctx, adminID, postID)
	if err != nil {
		return nil, fmt.Errorf("check existing report: %w", err)
	}
	if exists {
		return nil, appErrors.NewConflict("this post has already been reported by you")
	}

	if req.Severity == ReportSeverityBlacklist {
		return s.handleBlacklistReport(ctx, techID, postID, adminID, post.Title, req)
	}

	return s.handleWarningReport(ctx, techID, postID, adminID, post.Title, req)
}

func (s *service) handleBlacklistReport(
	ctx context.Context,
	techID, postID, adminID uint,
	postTitle string,
	req CreatePostReportDTO,
) (*PostReportResponse, error) {
	report := &TechnicianPostReport{
		PostID:       postID,
		TechnicianID: techID,
		AdminID:      adminID,
		ReportType:   req.ReportType,
		Reason:       req.Reason,
		Severity:     req.Severity,
		DeletePost:   req.DeletePost,
	}

	err := s.repo.DB().WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(report).Error; err != nil {
			return fmt.Errorf("create report: %w", err)
		}
		if req.DeletePost {
			if err := tx.Where("id = ? AND technician_id = ?", postID, techID).
				Delete(&TechnicianPost{}).Error; err != nil {
				return fmt.Errorf("delete post: %w", err)
			}
		}

		now := time.Now()
		if err := tx.Table("technicians").
			Where("id = ?", techID).
			Updates(map[string]any{
				"is_available": false,
				"banned_at":    now,
			}).Error; err != nil {
			return fmt.Errorf("blacklist technician: %w", err)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	if s.notif != nil {
		go s.sendBlacklistNotification(context.Background(), techID, postID, postTitle, req)
	}

	if err := s.repo.DB().WithContext(ctx).Preload("Admin").First(report, report.ID).Error; err != nil {
		return s.toReportResponse(ctx, report, true), nil
	}
	return s.toReportResponse(ctx, report, true), nil
}

func (s *service) handleWarningReport(
	ctx context.Context,
	techID, postID, adminID uint,
	postTitle string,
	req CreatePostReportDTO,
) (*PostReportResponse, error) {
	warningCount, err := s.repo.CountWarningsByTechnician(ctx, techID)
	if err != nil {
		return nil, fmt.Errorf("count warnings: %w", err)
	}

	newWarningCount := warningCount + 1

	shouldRestrict := newWarningCount >= WarningThresholdRestrict

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
		if req.DeletePost {
			if err := tx.Where("id = ? AND technician_id = ?", postID, techID).
				Delete(&TechnicianPost{}).Error; err != nil {
				return fmt.Errorf("delete post: %w", err)
			}
		}
		if shouldRestrict {
			now := time.Now()

			if err := tx.Table("technicians").
				Where("id = ? AND banned_at IS NULL", techID).
				Update("banned_at", now).Error; err != nil {
				return fmt.Errorf("restrict technician: %w", err)
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	if s.notif != nil {
		go s.sendWarningNotification(context.Background(), techID, postID, postTitle, req, newWarningCount, shouldRestrict)
	}

	if err := s.repo.DB().WithContext(ctx).Preload("Admin").First(report, report.ID).Error; err != nil {
		return s.toReportResponse(ctx, report, true), nil
	}
	return s.toReportResponse(ctx, report, true), nil
}

func (s *service) sendBlacklistNotification(
	ctx context.Context,
	techID, postID uint,
	postTitle string,
	req CreatePostReportDTO,
) {
	_, err := s.notif.Create(ctx, notification.CreateNotificationInput{
		RecipientRole: notification.RoleTechnician,
		RecipientID:   techID,
		Type:          "POST_BLACKLISTED",
		Title:         "บัญชีของคุณถูกระงับการใช้งาน 🚫",
		Message: fmt.Sprintf(
			"ผลงาน \"%s\" ถูกรายงานประเภท: %s บัญชีของคุณถูกระงับการใช้งานทันที กรุณาติดต่อทีมงาน",
			postTitle, req.ReportType,
		),
		EntityType: "post",
		EntityID:   postID,
		Data: map[string]any{
			"post_id":     postID,
			"report_type": req.ReportType,
			"severity":    req.Severity,
			"banned":      true,
		},
	})
	if err != nil {
		slog.Warn("failed to send blacklist notification", "technician_id", techID, "error", err)
	}
}

func (s *service) sendWarningNotification(
	ctx context.Context,
	techID, postID uint,
	postTitle string,
	req CreatePostReportDTO,
	warningCount int64,
	shouldRestrict bool,
) {
	var title, message, notifType string

	switch {
	case shouldRestrict:
		notifType = "POST_RESTRICTED"
		title = fmt.Sprintf("คำเตือนครั้งที่ %d — บัญชีถูกจำกัดการใช้งาน ⛔", warningCount)
		message = fmt.Sprintf(
			"ผลงาน \"%s\" ถูกรายงานในประเภท: %s คุณได้รับคำเตือนครั้งที่ %d บัญชีของคุณถูกจำกัดการรับงานใหม่ และจะถูกปิดใช้งานภายใน %d วัน หากไม่มีการแก้ไข",
			postTitle, req.ReportType, warningCount, RestrictGracePeriodDays,
		)
	default:
		notifType = "POST_WARNING"
		title = fmt.Sprintf("คำเตือนครั้งที่ %d ⚠️", warningCount)
		message = fmt.Sprintf(
			"ผลงาน \"%s\" ถูกรายงานในประเภท: %s (คำเตือน %d/3 ครั้ง หากถึง 4 ครั้งบัญชีจะถูกจำกัดและปิดใช้งานภายใน %d วัน)",
			postTitle, req.ReportType, warningCount, RestrictGracePeriodDays,
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
			"restricted":    shouldRestrict,
		},
	})
	if err != nil {
		slog.Warn("failed to send warning notification", "technician_id", techID, "error", err)
	}
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
		resp := s.toReportResponse(ctx, &reports[i], isAdmin)
		items = append(items, *resp)
	}

	return &PostReportListResponse{
		Items:   items,
		Total:   total,
		Page:    q.Page,
		PerPage: q.PerPage,
	}, nil
}

func (s *service) toReportResponse(ctx context.Context, r *TechnicianPostReport, showAdmin bool) *PostReportResponse {
	var adminResp AdminResponse
	if showAdmin && r.Admin != nil {
		avatarURL := ""
		if r.Admin.Avatar != nil && *r.Admin.Avatar != "" {
			if signed, err := s.storage.PresignGet(ctx, *r.Admin.Avatar, imagePresignTTL, false); err == nil {
				avatarURL = signed
			}
		}
		adminResp = AdminResponse{
			ID:        r.Admin.ID,
			FirstName: r.Admin.FirstName,
			LastName:  r.Admin.LastName,
			AvatarURL: avatarURL,
		}
	}

	return &PostReportResponse{
		ID:           r.ID,
		PostID:       r.PostID,
		TechnicianID: r.TechnicianID,
		ReportType:   r.ReportType,
		Reason:       r.Reason,
		Severity:     r.Severity,
		DeletePost:   r.DeletePost,
		Admin:        adminResp,
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
