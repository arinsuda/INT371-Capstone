package criminalcheck

import (
	"context"
	"fmt"
	"log"
	"strings"

	"gorm.io/gorm"

	"changsure-core-service/internal/modules/ocr/infra"
	"changsure-core-service/internal/modules/technician"
)

type VerificationResult struct {
	TechnicianID  uint
	NationalID    string
	ExtractedName string
	SystemName    string
	Status        CheckStatus
	Note          string
	Message       string
}

func ProcessVerification(
	ctx context.Context,
	db *gorm.DB,
	technicianID uint,
	ocrResult *infra.OCRResult,
	criminalRepo Repository,
	techRepo technician.Repository,
) (*VerificationResult, error) {

	// guard: db nil จะทำให้ panic ใน SaveLog ภายใน transaction
	if db == nil {
		return nil, fmt.Errorf("ProcessVerification: db is nil — check OCRWorkerDeps.DB wiring")
	}

	rawOCRText := strings.TrimSpace(ocrResult.IDNumber + " " + ocrResult.NameRaw)

	// saveLog สำหรับ early-return ก่อนถึง transaction
	// ใช้ criminalRepo โดยตรง (ไม่ผ่าน tx) เพราะยังไม่มี transaction เปิดอยู่
	saveEarlyLog := func(logItem *VerificationLog) {
		if err := criminalRepo.SaveLog(logItem); err != nil {
			log.Printf("[WARN] save early verification log failed: %v", err)
		}
	}

	// --- 1) OCR validations ---
	if ocrResult.IDNumber == "" {
		saveEarlyLog(&VerificationLog{
			TechnicianID: technicianID,
			Status:       StatusOCRFailed,
			Note:         "ไม่สามารถ extract เลขบัตรประชาชนจากรูปภาพได้",
			RawOCRText:   rawOCRText,
		})
		return &VerificationResult{
			TechnicianID: technicianID,
			Status:       StatusOCRFailed,
			Note:         "ไม่สามารถ extract เลขบัตรประชาชนจากรูปภาพได้",
			Message:      "กรุณาถ่ายรูปบัตรประชาชนให้ชัดเจนและครบถ้วน",
		}, nil
	}

	if !ocrResult.Valid {
		saveEarlyLog(&VerificationLog{
			TechnicianID: technicianID,
			NationalID:   ocrResult.IDNumber,
			Status:       StatusOCRFailed,
			Note:         "เลข 13 หลักไม่ผ่าน checksum",
			RawOCRText:   rawOCRText,
		})
		return &VerificationResult{
			TechnicianID: technicianID,
			NationalID:   ocrResult.IDNumber,
			Status:       StatusOCRFailed,
			Note:         "เลข 13 หลักไม่ผ่าน checksum",
			Message:      "กรุณาถ่ายรูปบัตรประชาชนให้ชัดเจนและครบถ้วน",
		}, nil
	}

	if ocrResult.NameRaw == "" {
		saveEarlyLog(&VerificationLog{
			TechnicianID: technicianID,
			NationalID:   ocrResult.IDNumber,
			Status:       StatusNameNotExtracted,
			Note:         "อ่านเลขบัตรได้ แต่ไม่สามารถ extract ชื่อจากรูปภาพได้",
			RawOCRText:   rawOCRText,
		})
		return &VerificationResult{
			TechnicianID: technicianID,
			NationalID:   ocrResult.IDNumber,
			Status:       StatusNameNotExtracted,
			Note:         "อ่านเลขบัตรได้ แต่ไม่สามารถ extract ชื่อจากรูปภาพได้",
			Message:      "กรุณาถ่ายรูปบัตรประชาชนให้เห็นชื่อ-นามสกุลชัดเจน",
		}, nil
	}

	// --- 2) load technician ---
	tech, err := techRepo.FindByID(ctx, technicianID)
	if err != nil || tech == nil {
		return nil, ErrTechNotFound
	}
	systemName := tech.FirstName + " " + tech.LastName

	// --- 3) criminal check ---
	record, err := criminalRepo.FindByNationalID(ocrResult.IDNumber)
	if err != nil {
		return nil, fmt.Errorf("find criminal record: %w", err)
	}

	status, note, message := resolveStatus(record)

	// --- 4) name matching ---
	if status == StatusPassed {
		if !namesMatch(ocrResult.NameRaw, tech.FirstName, tech.LastName) {
			status = StatusReview
			note = fmt.Sprintf(
				"เลขบัตรผ่าน แต่ชื่อไม่ตรง — OCR: %q | ระบบ: %q",
				ocrResult.NameRaw, systemName,
			)
			message = "ชื่อในบัตรไม่ตรงกับชื่อในระบบ กรุณารอ admin ตรวจสอบ"
		}
	}

	// --- 5) transactional persist ---
	err = db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		txRepo := criminalRepo.WithTx(tx)
		txTechRepo := techRepo.WithTx(tx)

		// 5.1 save log
		if err := txRepo.SaveLog(&VerificationLog{
			TechnicianID: technicianID,
			NationalID:   ocrResult.IDNumber,
			Status:       status,
			Note:         note,
			RawOCRText:   rawOCRText,
		}); err != nil {
			return fmt.Errorf("save verification log: %w", err)
		}

		// 5.2 idempotent guard
		if technician.VerificationStatus(status) == tech.VerificationStatus {
			return nil
		}

		// 5.3 update technician verification status
		switch status {
		case StatusPassed:
			if err := txTechRepo.UpdateVerificationStatus(ctx, technicianID, technician.StatusPassed); err != nil {
				return fmt.Errorf("update status PASSED: %w", err)
			}
		case StatusFailed:
			if err := txTechRepo.UpdateVerificationStatus(ctx, technicianID, technician.StatusFailed); err != nil {
				return fmt.Errorf("update status FAILED: %w", err)
			}
		case StatusReview:
			if err := txTechRepo.UpdateVerificationStatus(ctx, technicianID, technician.StatusReview); err != nil {
				return fmt.Errorf("update status REVIEW: %w", err)
			}
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	// --- 6) response ---
	return &VerificationResult{
		TechnicianID:  technicianID,
		NationalID:    ocrResult.IDNumber,
		ExtractedName: ocrResult.NameRaw,
		SystemName:    systemName,
		Status:        status,
		Note:          note,
		Message:       message,
	}, nil
}