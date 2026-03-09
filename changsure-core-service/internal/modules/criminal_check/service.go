package criminalcheck

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"

	ocrservice "changsure-core-service/internal/modules/ocr/service"
	"changsure-core-service/internal/modules/technician"
	"gorm.io/gorm"
)

var (
	ErrLogNotFound            = errors.New("verification log not found")
	ErrTechNotFound           = errors.New("technician not found")
	ErrCriminalRecordNotFound = errors.New("criminal record not found")
	ErrNationalIDDuplicate    = errors.New("national id already exists")
)

var nationalIDRegex = regexp.MustCompile(`\b[0-9]{13}\b`)

type Service interface {
	VerifyIdentity(ctx context.Context, technicianID uint, imageBytes []byte, filename string) (*VerifyIdentityResponse, error)

	ListLogs(ctx context.Context, filter ListLogsFilter) (*ListLogsResponse, error)
	GetLogsByTechnician(ctx context.Context, technicianID uint) ([]VerificationLogResponse, error)
	UpdateLogStatus(ctx context.Context, adminID uint, logID uint, req UpdateLogStatusRequest) (*VerificationLogResponse, error)
	OverrideIsVerified(ctx context.Context, adminID uint, technicianID uint, req OverrideIsVerifiedRequest) error
	GetStats(ctx context.Context) (*VerificationStatResponse, error)

	ListCriminalRecords(ctx context.Context, page, pageSize int, status string) ([]CriminalRecordResponse, int64, error)
	GetCriminalRecord(ctx context.Context, id uint) (*CriminalRecordResponse, error)
	CreateCriminalRecord(ctx context.Context, req CreateCriminalRecordRequest) (*CriminalRecordResponse, error)
	UpdateCriminalRecord(ctx context.Context, id uint, req UpdateCriminalRecordRequest) (*CriminalRecordResponse, error)
	DeleteCriminalRecord(ctx context.Context, id uint) error
}

type service struct {
	repo       Repository
	techRepo   technician.Repository
	ocrService ocrservice.OCRService
}

func NewService(repo Repository, techRepo technician.Repository, ocrSvc ocrservice.OCRService) Service {
	return &service{repo: repo, techRepo: techRepo, ocrService: ocrSvc}
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
		tech.IsVerified = true
		_ = s.techRepo.Update(ctx, tech)
	}

	return &VerifyIdentityResponse{
		TechnicianID:  technicianID,
		NationalID:    nationalID,
		ExtractedName: extractedName,
		SystemName:    systemName,
		Status:        status,
		Note:          note,
		IsVerified:    isVerified,
		Message:       message,
	}, nil
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

	if req.Status == StatusPassed {
		if tech, err := s.techRepo.FindByID(ctx, log.TechnicianID); err == nil && tech != nil {
			tech.IsVerified = true
			_ = s.techRepo.Update(ctx, tech)
		}
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

func (s *service) OverrideIsVerified(ctx context.Context, adminID uint, technicianID uint, req OverrideIsVerifiedRequest) error {
	tech, err := s.techRepo.FindByID(ctx, technicianID)
	if err != nil || tech == nil {
		return ErrTechNotFound
	}

	previousValue := fmt.Sprintf("%v", tech.IsVerified)
	newValue := fmt.Sprintf("%v", req.IsVerified)

	tech.IsVerified = req.IsVerified
	if err := s.techRepo.Update(ctx, tech); err != nil {
		return fmt.Errorf("update technician: %w", err)
	}

	_ = s.repo.SaveOverrideLog(&AdminOverrideLog{
		AdminID:       adminID,
		TechnicianID:  technicianID,
		TargetType:    "is_verified",
		TargetID:      technicianID,
		PreviousValue: previousValue,
		NewValue:      newValue,
		Reason:        req.Reason,
	})

	return nil
}

func (s *service) GetStats(ctx context.Context) (*VerificationStatResponse, error) {
	return s.repo.GetStats()
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
		resp.IsVerified = tech.IsVerified
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

func (s *service) ListCriminalRecords(ctx context.Context, page, pageSize int, status string) ([]CriminalRecordResponse, int64, error) {
	records, total, err := s.repo.ListCriminalRecords(page, pageSize, status)
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

	record := &MockCriminalRecord{
		NationalID: req.NationalID,
		FullName:   req.FullName,
		Status:     req.Status,
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
	if req.FullName != nil {
		updates["full_name"] = *req.FullName
	}
	if req.Status != nil {
		updates["status"] = *req.Status
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

func toCriminalRecordResponse(r MockCriminalRecord) CriminalRecordResponse {
	return CriminalRecordResponse{
		ID:         r.ID,
		NationalID: r.NationalID,
		FullName:   r.FullName,
		Status:     r.Status,
		Note:       r.Note,
		CreatedAt:  r.CreatedAt,
		UpdatedAt:  r.UpdatedAt,
	}
}
