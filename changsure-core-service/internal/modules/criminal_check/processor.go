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

	rawOCRText := strings.TrimSpace(ocrResult.IDNumber + " " + ocrResult.NameRaw)

	// --- helper: save log (non-fatal) ---
	saveLog := func(tx *gorm.DB, logItem *VerificationLog) {
		if err := criminalRepo.WithTx(tx).SaveLog(logItem); err != nil {
			log.Printf("[WARN] save verification log failed: %v", err)
		}
	}

	// --- 1) OCR validations ---
	if ocrResult.IDNumber == "" {
		saveLog(db, &VerificationLog{
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
		saveLog(db, &VerificationLog{
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
		saveLog(db, &VerificationLog{
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
			status = StatusReview // ✅ ใช้ REVIEW แทน PENDING
			note = fmt.Sprintf(
				"เลขบัตรผ่าน แต่ชื่อไม่ตรง — OCR: %q | ระบบ: %q",
				ocrResult.NameRaw, systemName,
			)
			message = "ชื่อในบัตรไม่ตรงกับชื่อในระบบ กรุณารอ admin ตรวจสอบ"
		}
	}

	// --- 5) transactional persist ---
	err = db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {

		// 5.1 save log
		if err := criminalRepo.WithTx(tx).SaveLog(&VerificationLog{
			TechnicianID: technicianID,
			NationalID:   ocrResult.IDNumber,
			Status:       status,
			Note:         note,
			RawOCRText:   rawOCRText,
		}); err != nil {
			return fmt.Errorf("save verification log: %w", err)
		}

		// 5.2 idempotent guard (กัน update ซ้ำ)
		// ถ้า status เดิมเหมือนใหม่ → ไม่ต้อง update
		if technician.VerificationStatus(status) == tech.VerificationStatus {
			return nil
		}

		// 5.3 update technician status
		switch status {
		case StatusPassed:
			if err := techRepo.WithTx(tx).
				UpdateVerificationStatus(ctx, technicianID, technician.StatusPassed); err != nil {
				return fmt.Errorf("update status PASSED: %w", err)
			}

		case StatusFailed:
			if err := techRepo.WithTx(tx).
				UpdateVerificationStatus(ctx, technicianID, technician.StatusFailed); err != nil {
				return fmt.Errorf("update status FAILED: %w", err)
			}

		case StatusReview:
			if err := techRepo.WithTx(tx).
				UpdateVerificationStatus(ctx, technicianID, technician.StatusReview); err != nil {
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
