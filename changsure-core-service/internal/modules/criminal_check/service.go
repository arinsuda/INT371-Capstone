package criminalcheck

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"gorm.io/gorm"

	backgroundjob "changsure-core-service/internal/modules/background_job"
	"changsure-core-service/internal/modules/notification"
	ocrservice "changsure-core-service/internal/modules/ocr/service"
	"changsure-core-service/internal/modules/technician"
	"changsure-core-service/pkg/storage"
)

var (
	ErrLogNotFound            = errors.New("verification log not found")
	ErrTechNotFound           = errors.New("technician not found")
	ErrCriminalRecordNotFound = errors.New("criminal record not found")
	ErrNationalIDDuplicate    = errors.New("national id already exists")
)

type Service interface {
	EnqueueVerification(ctx context.Context, technicianID uint, imageBytes []byte, filename string) (jobID uint, err error)

	VerifyIdentity(ctx context.Context, technicianID uint, imageBytes []byte, filename string) (*VerifyIdentityResponse, error)
	GetJobStatus(ctx context.Context, jobID uint) (*JobStatusResponse, error)

	ListLogs(ctx context.Context, filter ListLogsFilter) (*ListLogsResponse, error)
	GetLogsByTechnician(ctx context.Context, technicianID uint) ([]VerificationLogResponse, error)
	UpdateLogStatus(ctx context.Context, adminID uint, logID uint, req UpdateLogStatusRequest) (*VerificationLogResponse, error)
	OverrideVerificationStatus(
		ctx context.Context,
		adminID uint,
		technicianID uint,
		req OverrideVerificationStatusRequest,
	) error
	GetStats(ctx context.Context) (*VerificationStatResponse, error)

	ListPendingManualJobs(ctx context.Context, page, pageSize int) ([]backgroundjob.BackgroundJob, int64, error)
	ApproveJob(ctx context.Context, adminID uint, jobID uint, reason string) error
	RejectJob(ctx context.Context, adminID uint, jobID uint, reason string) error

	ListCriminalRecords(ctx context.Context, page, pageSize int) ([]CriminalRecordResponse, int64, error)
	GetCriminalRecord(ctx context.Context, id uint) (*CriminalRecordResponse, error)
	CreateCriminalRecord(ctx context.Context, req CreateCriminalRecordRequest) (*CriminalRecordResponse, error)
	UpdateCriminalRecord(ctx context.Context, id uint, req UpdateCriminalRecordRequest) (*CriminalRecordResponse, error)
	DeleteCriminalRecord(ctx context.Context, id uint) error
	GetVerificationDetail(ctx context.Context, technicianID uint) (*TechnicianVerificationDetail, error)
}

type service struct {
	repo        Repository
	techRepo    technician.Repository
	ocrService  ocrservice.OCRService
	notiService notification.Service
	jobRepo     backgroundjob.Repository
	storage     storage.Storage
}

func NewService(
	repo Repository,
	techRepo technician.Repository,
	ocrSvc ocrservice.OCRService,
	notiSvc notification.Service,
	jobRepo backgroundjob.Repository,
	store storage.Storage,
) Service {
	return &service{
		repo:        repo,
		techRepo:    techRepo,
		ocrService:  ocrSvc,
		notiService: notiSvc,
		jobRepo:     jobRepo,
		storage:     store,
	}
}

func (s *service) EnqueueVerification(ctx context.Context, technicianID uint, imageBytes []byte, filename string) (uint, error) {
	tech, err := s.techRepo.FindByID(ctx, technicianID)
	if err != nil || tech == nil {
		return 0, ErrTechNotFound
	}

	objectKey, err := s.storage.UploadFile(
		ctx,
		bytes.NewReader(imageBytes),
		filename,
		fmt.Sprintf("ocr-uploads/%d", technicianID),
		int64(len(imageBytes)),
		"image/jpeg",
	)
	if err != nil {
		return 0, fmt.Errorf("upload image: %w", err)
	}

	if err := s.techRepo.UpdateIDCardImage(ctx, technicianID, objectKey); err != nil {
		fmt.Printf("[WARN] failed to save id_card_image_url for tech %d: %v\n", technicianID, err)
	}

	job, err := s.jobRepo.Enqueue(ctx, backgroundjob.JobTypeOCRVerify, backgroundjob.OCRVerifyPayload{
		TechnicianID: technicianID,
		ImagePath:    objectKey,
		Filename:     filename,
	})
	if err != nil {
		return 0, fmt.Errorf("enqueue job: %w", err)
	}

	return job.ID, nil
}

func (s *service) VerifyIdentity(ctx context.Context, technicianID uint, imageBytes []byte, filename string) (*VerifyIdentityResponse, error) {
	ocrResult, err := s.ocrService.ProcessOCR(imageBytes, filename)
	if err != nil {
		return nil, fmt.Errorf("ocr failed: %w", err)
	}

	var rawTexts []string
	for _, item := range ocrResult.Items {
		rawTexts = append(rawTexts, item.Text)
	}
	rawOCRText := strings.Join(rawTexts, " ")

	nationalID, idCardY := extractNationalIDWithY(ocrResult.Items)
	if nationalID == "" {
		_ = s.repo.SaveLog(&VerificationLog{
			TechnicianID: technicianID,
			Status:       StatusOCRFailed,
			Note:         "ไม่สามารถ extract เลขบัตรประชาชนจากรูปภาพได้",
			RawOCRText:   rawOCRText,
		})
		return &VerifyIdentityResponse{
			TechnicianID: technicianID,
			Status:       StatusOCRFailed,
			Note:         "ไม่สามารถ extract เลขบัตรประชาชนจากรูปภาพได้",
			Message:      "กรุณาถ่ายรูปบัตรประชาชนให้ชัดเจนและครบถ้วน",
		}, nil
	}

	extractedName := extractThaiName(ocrResult.Items, idCardY)
	if extractedName == "" {
		_ = s.repo.SaveLog(&VerificationLog{
			TechnicianID: technicianID,
			NationalID:   nationalID,
			Status:       StatusNameNotExtracted,
			Note:         "อ่านเลขบัตรได้ แต่ไม่สามารถ extract ชื่อจากรูปภาพได้",
			RawOCRText:   rawOCRText,
		})
		return &VerifyIdentityResponse{
			TechnicianID: technicianID,
			NationalID:   nationalID,
			Status:       StatusNameNotExtracted,
			Note:         "อ่านเลขบัตรได้ แต่ไม่สามารถ extract ชื่อจากรูปภาพได้",
			Message:      "กรุณาถ่ายรูปบัตรประชาชนให้เห็นชื่อ-นามสกุลชัดเจน",
		}, nil
	}

	tech, err := s.techRepo.FindByID(ctx, technicianID)
	if err != nil || tech == nil {
		return nil, ErrTechNotFound
	}
	systemName := tech.FirstName + " " + tech.LastName

	record, err := s.repo.FindByNationalID(nationalID)
	if err != nil {
		return nil, fmt.Errorf("find criminal record: %w", err)
	}

	status, note, message, isVerified := resolveStatus(record)

	if status == StatusPassed {
		if !namesMatch(extractedName, tech.FirstName, tech.LastName) {
			status = StatusPending
			isVerified = false
			note = fmt.Sprintf(
				"เลขบัตรผ่าน แต่ชื่อไม่ตรง — OCR: %q | ระบบ: %q",
				extractedName, systemName,
			)
			message = "ชื่อในบัตรไม่ตรงกับชื่อในระบบ กรุณารอ admin ตรวจสอบ"
		}
	}

	_ = s.repo.SaveLog(&VerificationLog{
		TechnicianID: technicianID,
		NationalID:   nationalID,
		Status:       status,
		Note:         note,
		RawOCRText:   rawOCRText,
	})

	if isVerified {
		_ = s.techRepo.UpdateVerificationStatus(ctx, technicianID, technician.StatusPassed)
		s.notifyVerificationResult(ctx, technicianID, StatusPassed, note)
	}

	return &VerifyIdentityResponse{
		TechnicianID:  technicianID,
		NationalID:    nationalID,
		ExtractedName: extractedName,
		SystemName:    systemName,
		Status:        status,
		Note:          note,
		Message:       message,
	}, nil
}

func (s *service) GetJobStatus(ctx context.Context, jobID uint) (*JobStatusResponse, error) {
	job, err := s.jobRepo.GetByID(ctx, jobID)
	if err != nil {
		return nil, err
	}

	resp := &JobStatusResponse{
		JobID:      job.ID,
		Status:     string(job.Status),
		RetryCount: job.RetryCount,
		ErrorMsg:   job.ErrorMsg,
		CreatedAt:  job.CreatedAt,
		StartedAt:  job.StartedAt,
		FinishedAt: job.FinishedAt,
	}

	var payload backgroundjob.OCRVerifyPayload
	if err := json.Unmarshal(job.Payload, &payload); err == nil {
		logs, _ := s.repo.GetLogsByTechnicianID(payload.TechnicianID)
		if len(logs) > 0 {
			latest := logs[0]
			resp.VerifyStatus = string(latest.Status)
			resp.VerifyNote = latest.Note

			if tech, err := s.techRepo.FindByID(ctx, payload.TechnicianID); err == nil && tech != nil {

			}
		}
	}

	return resp, nil
}

func (s *service) ListPendingManualJobs(ctx context.Context, page, pageSize int) ([]backgroundjob.BackgroundJob, int64, error) {
	return s.jobRepo.ListByStatus(ctx, backgroundjob.JobTypeOCRVerify, backgroundjob.JobStatusPendingManual, page, pageSize)
}

func (s *service) ApproveJob(ctx context.Context, adminID uint, jobID uint, reason string) error {
	job, err := s.jobRepo.GetByID(ctx, jobID)
	if err != nil {
		return fmt.Errorf("get job: %w", err)
	}

	var payload backgroundjob.OCRVerifyPayload
	if err := json.Unmarshal(job.Payload, &payload); err != nil {
		return fmt.Errorf("parse payload: %w", err)
	}

	if err := s.jobRepo.MarkDone(ctx, jobID); err != nil {
		return fmt.Errorf("mark done: %w", err)
	}

	_ = s.techRepo.UpdateVerificationStatus(ctx, payload.TechnicianID, technician.StatusPassed)

	_ = s.repo.SaveOverrideLog(&AdminOverrideLog{
		AdminID:       adminID,
		TechnicianID:  payload.TechnicianID,
		TargetType:    "ocr_job",
		TargetID:      jobID,
		PreviousValue: string(backgroundjob.JobStatusPendingManual),
		NewValue:      "APPROVED",
		Reason:        reason,
	})

	s.notifyVerificationResult(ctx, payload.TechnicianID, StatusPassed, reason)
	return nil
}

func (s *service) RejectJob(ctx context.Context, adminID uint, jobID uint, reason string) error {
	job, err := s.jobRepo.GetByID(ctx, jobID)
	if err != nil {
		return fmt.Errorf("get job: %w", err)
	}

	var payload backgroundjob.OCRVerifyPayload
	if err := json.Unmarshal(job.Payload, &payload); err != nil {
		return fmt.Errorf("parse payload: %w", err)
	}

	_, _ = s.jobRepo.MarkFailed(ctx, jobID, fmt.Sprintf("rejected by admin: %s", reason))

	_ = s.techRepo.UpdateVerificationStatus(ctx, payload.TechnicianID, technician.StatusFailed)

	_ = s.repo.SaveOverrideLog(&AdminOverrideLog{
		AdminID:       adminID,
		TechnicianID:  payload.TechnicianID,
		TargetType:    "ocr_job",
		TargetID:      jobID,
		PreviousValue: string(backgroundjob.JobStatusPendingManual),
		NewValue:      "REJECTED",
		Reason:        reason,
	})

	s.notifyVerificationResult(ctx, payload.TechnicianID, StatusFailed, reason)
	return nil
}

func (s *service) UpdateLogStatus(ctx context.Context, adminID uint, logID uint, req UpdateLogStatusRequest) (*VerificationLogResponse, error) {
	log, err := s.repo.GetLogByID(logID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrLogNotFound
		}
		return nil, fmt.Errorf("get log: %w", err)
	}

	previousStatus := string(log.Status)

	if err := s.repo.UpdateLogStatus(logID, req.Status, req.Reason); err != nil {
		return nil, fmt.Errorf("update log status: %w", err)
	}

	_ = s.repo.SaveOverrideLog(&AdminOverrideLog{
		AdminID:       adminID,
		TechnicianID:  log.TechnicianID,
		TargetType:    "verification_log",
		TargetID:      logID,
		PreviousValue: previousStatus,
		NewValue:      string(req.Status),
		Reason:        req.Reason,
	})

	switch req.Status {
	case StatusPassed:
		_ = s.techRepo.UpdateVerificationStatus(ctx, log.TechnicianID, technician.StatusPassed)
		s.notifyVerificationResult(ctx, log.TechnicianID, StatusPassed, req.Reason)
	case StatusFailed:
		_ = s.techRepo.UpdateVerificationStatus(ctx, log.TechnicianID, technician.StatusFailed)
		s.notifyVerificationResult(ctx, log.TechnicianID, StatusFailed, req.Reason)
	}

	updated, _ := s.repo.GetLogByID(logID)
	if updated == nil {
		updated = log
		updated.Status = req.Status
		updated.Note = req.Reason
	}

	resp, _ := s.enrichLog(ctx, *updated)
	return &resp, nil
}

func (s *service) OverrideVerificationStatus(
	ctx context.Context,
	adminID uint,
	technicianID uint,
	req OverrideVerificationStatusRequest,
) error {

	tech, err := s.techRepo.FindByID(ctx, technicianID)
	if err != nil || tech == nil {
		return ErrTechNotFound
	}

	targetStatus := technician.VerificationStatus(req.Status)

	if err := s.techRepo.UpdateVerificationStatus(ctx, technicianID, targetStatus); err != nil {
		return fmt.Errorf("update verification status: %w", err)
	}

	_ = s.repo.SaveOverrideLog(&AdminOverrideLog{
		AdminID:       adminID,
		TechnicianID:  technicianID,
		TargetType:    "verification_status",
		TargetID:      technicianID,
		PreviousValue: string(tech.VerificationStatus),
		NewValue:      string(targetStatus),
		Reason:        req.Reason,
	})

	return nil
}

func (s *service) GetStats(ctx context.Context) (*VerificationStatResponse, error) {
	return s.repo.GetStats()
}

func (s *service) ListLogs(ctx context.Context, filter ListLogsFilter) (*ListLogsResponse, error) {
	logs, total, err := s.repo.ListLogs(filter)
	if err != nil {
		return nil, fmt.Errorf("list logs: %w", err)
	}
	responses := make([]VerificationLogResponse, 0, len(logs))
	for _, l := range logs {
		resp, err := s.enrichLog(ctx, l)
		if err != nil {
			continue
		}
		responses = append(responses, resp)
	}
	return &ListLogsResponse{
		Logs:     responses,
		Total:    total,
		Page:     filter.Page,
		PageSize: filter.PageSize,
	}, nil
}

func (s *service) GetLogsByTechnician(ctx context.Context, technicianID uint) ([]VerificationLogResponse, error) {
	logs, err := s.repo.GetLogsByTechnicianID(technicianID)
	if err != nil {
		return nil, fmt.Errorf("get logs by technician: %w", err)
	}
	responses := make([]VerificationLogResponse, 0, len(logs))
	for _, l := range logs {
		resp, err := s.enrichLog(ctx, l)
		if err != nil {
			continue
		}
		responses = append(responses, resp)
	}
	return responses, nil
}

func (s *service) GetVerificationDetail(ctx context.Context, technicianID uint) (*TechnicianVerificationDetail, error) {
	tech, err := s.techRepo.FindByID(ctx, technicianID)
	if err != nil || tech == nil {
		return nil, ErrTechNotFound
	}

	detail := &TechnicianVerificationDetail{
		TechnicianID:       tech.ID,
		FirstName:          tech.FirstName,
		LastName:           tech.LastName,
		Email:              tech.Email,
		Phone:              tech.Phone,
		VerificationStatus: string(tech.VerificationStatus),
		RegisteredAt:       tech.CreatedAt.Unix(),
	}

	if tech.AvatarURL != nil && *tech.AvatarURL != "" {
		if signed, err := s.storage.PresignGet(ctx, *tech.AvatarURL, time.Hour, false); err == nil {
			detail.AvatarURL = &signed
		}
	}

	if tech.IDCardImageURL != nil && *tech.IDCardImageURL != "" {
		if signed, err := s.storage.PresignGet(ctx, *tech.IDCardImageURL, time.Hour, false); err == nil {
			detail.IDCardImageURL = &signed
		}
	}

	for _, ts := range tech.Services {
		if ts.Service.ID != 0 {
			detail.ServiceNames = append(detail.ServiceNames, ts.Service.SerName)
		}
	}
	for _, area := range tech.ServiceAreas {
		if area.Province.ID != 0 {
			detail.ProvinceNames = append(detail.ProvinceNames, area.Province.NameTH)
		}
	}

	logs, err := s.repo.GetLogsByTechnicianID(technicianID)
	if err == nil && len(logs) > 0 {
		latest := logs[0]
		detail.NationalID = &latest.NationalID

		if extracted := parseExtractedNameFromNote(latest.Note); extracted != "" {
			detail.ExtractedName = &extracted
		}

		enriched, err := s.enrichLog(ctx, latest)
		if err == nil {
			detail.LatestLog = &enriched
		}
	}

	if detail.NationalID != nil && *detail.NationalID != "" {
		record, err := s.repo.GetCriminalRecordByNationalID(*detail.NationalID)
		if err == nil && record != nil {
			resp := toCriminalRecordResponse(*record)
			detail.CriminalRecord = &resp
		}
	}

	pendingJobs, _, err := s.jobRepo.ListByStatus(ctx,
		backgroundjob.JobTypeOCRVerify,
		backgroundjob.JobStatusPendingManual,
		1, 100,
	)
	if err == nil {
		for _, job := range pendingJobs {
			var payload backgroundjob.OCRVerifyPayload
			if err := json.Unmarshal(job.Payload, &payload); err == nil {
				if payload.TechnicianID == technicianID {
					detail.PendingJobID = &job.ID
					break
				}
			}
		}
	}

	return detail, nil
}

func (s *service) ListCriminalRecords(ctx context.Context, page, pageSize int) ([]CriminalRecordResponse, int64, error) {
	records, total, err := s.repo.ListCriminalRecords(page, pageSize)
	if err != nil {
		return nil, 0, fmt.Errorf("list criminal records: %w", err)
	}
	resp := make([]CriminalRecordResponse, 0, len(records))
	for _, r := range records {
		resp = append(resp, toCriminalRecordResponse(r))
	}
	return resp, total, nil
}

func (s *service) GetCriminalRecord(ctx context.Context, id uint) (*CriminalRecordResponse, error) {
	record, err := s.repo.GetCriminalRecordByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrCriminalRecordNotFound
		}
		return nil, fmt.Errorf("get criminal record: %w", err)
	}
	resp := toCriminalRecordResponse(*record)
	return &resp, nil
}

func (s *service) CreateCriminalRecord(ctx context.Context, req CreateCriminalRecordRequest) (*CriminalRecordResponse, error) {
	existing, err := s.repo.GetCriminalRecordByNationalID(req.NationalID)
	if err != nil {
		return nil, fmt.Errorf("check national id: %w", err)
	}
	if existing != nil {
		return nil, ErrNationalIDDuplicate
	}
	record := &CriminalBlacklist{
		NationalID: req.NationalID,
		FullName:   req.FullName,
		Note:       req.Note,
	}
	if err := s.repo.CreateCriminalRecord(record); err != nil {
		return nil, fmt.Errorf("create criminal record: %w", err)
	}
	resp := toCriminalRecordResponse(*record)
	return &resp, nil
}

func (s *service) UpdateCriminalRecord(ctx context.Context, id uint, req UpdateCriminalRecordRequest) (*CriminalRecordResponse, error) {
	if _, err := s.repo.GetCriminalRecordByID(id); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrCriminalRecordNotFound
		}
		return nil, fmt.Errorf("get criminal record: %w", err)
	}
	updates := map[string]interface{}{}
	if req.NationalID != nil {
		existing, err := s.repo.GetCriminalRecordByNationalID(*req.NationalID)
		if err != nil {
			return nil, fmt.Errorf("check national id: %w", err)
		}
		if existing != nil && existing.ID != id {
			return nil, ErrNationalIDDuplicate
		}
		updates["national_id"] = *req.NationalID
	}
	if req.FullName != nil {
		updates["full_name"] = *req.FullName
	}
	if req.Note != nil {
		updates["note"] = *req.Note
	}
	if len(updates) == 0 {
		return s.GetCriminalRecord(ctx, id)
	}
	if err := s.repo.UpdateCriminalRecord(id, updates); err != nil {
		return nil, fmt.Errorf("update criminal record: %w", err)
	}
	return s.GetCriminalRecord(ctx, id)
}

func (s *service) DeleteCriminalRecord(ctx context.Context, id uint) error {
	if _, err := s.repo.GetCriminalRecordByID(id); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrCriminalRecordNotFound
		}
		return fmt.Errorf("get criminal record: %w", err)
	}
	return s.repo.DeleteCriminalRecord(id)
}

func (s *service) getLatestNationalID(ctx context.Context, technicianID uint) string {
	logs, err := s.repo.GetLogsByTechnicianID(technicianID)
	if err != nil || len(logs) == 0 {
		return ""
	}
	return logs[0].NationalID
}

func (s *service) notifyVerificationResult(ctx context.Context, technicianID uint, status CheckStatus, note string) {
	if s.notiService == nil {
		return
	}

	var title, message, notiType string

	switch status {
	case StatusPassed:
		notiType = "IDENTITY_VERIFIED"
		title = "ยืนยันตัวตนสำเร็จ ✅"
		message = "บัตรประชาชนของคุณผ่านการตรวจสอบแล้ว คุณสามารถรับงานได้เลย"
	case StatusFailed:
		notiType = "IDENTITY_REJECTED"
		title = "ไม่ผ่านการตรวจสอบ ❌"
		message = "บัตรประชาชนของคุณไม่ผ่านการตรวจสอบ กรุณาติดต่อเจ้าหน้าที่"
		if note != "" {
			message = fmt.Sprintf("%s\nเหตุผล: %s", message, note)
		}
	default:
		return
	}

	_, _ = s.notiService.Create(ctx, notification.CreateNotificationInput{
		RecipientRole: notification.RoleTechnician,
		RecipientID:   technicianID,
		Type:          notiType,
		Title:         title,
		Message:       message,
		EntityType:    "technician",
		EntityID:      technicianID,
		Data:          map[string]any{"status": string(status), "note": note},
	})
}

func (s *service) enrichLog(ctx context.Context, l VerificationLog) (VerificationLogResponse, error) {
	resp := VerificationLogResponse{
		ID:           l.ID,
		TechnicianID: l.TechnicianID,
		NationalID:   l.NationalID,
		Status:       l.Status,
		Note:         l.Note,
		RawOCRText:   l.RawOCRText,
		CreatedAt:    l.CreatedAt,
	}

	if tech, err := s.techRepo.FindByID(ctx, l.TechnicianID); err == nil && tech != nil {
		resp.TechnicianName = tech.FirstName + " " + tech.LastName

		if tech.IDCardImageURL != nil && *tech.IDCardImageURL != "" {
			if signed, err := s.storage.PresignGet(ctx, *tech.IDCardImageURL, time.Hour, false); err == nil {
				resp.IDCardImageURL = &signed
			}
		}
	}

	if history, err := s.repo.GetOverrideHistory("verification_log", l.ID); err == nil {
		for _, h := range history {
			resp.OverrideHistory = append(resp.OverrideHistory, AdminOverrideLogResponse{
				ID:            h.ID,
				AdminID:       h.AdminID,
				TargetType:    h.TargetType,
				PreviousValue: h.PreviousValue,
				NewValue:      h.NewValue,
				Reason:        h.Reason,
				CreatedAt:     h.CreatedAt,
			})
		}
	}

	return resp, nil
}

func parseExtractedNameFromNote(note string) string {
	const marker = `OCR: "`
	idx := strings.Index(note, marker)
	if idx == -1 {
		return ""
	}
	rest := note[idx+len(marker):]
	end := strings.Index(rest, `"`)
	if end == -1 {
		return ""
	}
	return rest[:end]
}

func toCriminalRecordResponse(r CriminalBlacklist) CriminalRecordResponse {
	return CriminalRecordResponse{
		ID:         r.ID,
		NationalID: r.NationalID,
		FullName:   r.FullName,
		Note:       r.Note,
		CreatedAt:  r.CreatedAt,
		UpdatedAt:  r.UpdatedAt,
	}
}
