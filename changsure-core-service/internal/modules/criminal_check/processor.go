package criminalcheck

import (
	"context"
	"fmt"
	"strings"

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
	technicianID uint,
	ocrResult *infra.OCRResult,
	criminalRepo Repository,
	techRepo technician.Repository,
) (*VerificationResult, error) {

	rawOCRText := strings.TrimSpace(ocrResult.IDNumber + " " + ocrResult.NameRaw)

	if ocrResult.IDNumber == "" {
		_ = criminalRepo.SaveLog(&VerificationLog{
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
		_ = criminalRepo.SaveLog(&VerificationLog{
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
		_ = criminalRepo.SaveLog(&VerificationLog{
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

	tech, err := techRepo.FindByID(ctx, technicianID)
	if err != nil || tech == nil {
		return nil, ErrTechNotFound
	}
	systemName := tech.FirstName + " " + tech.LastName

	record, err := criminalRepo.FindByNationalID(ocrResult.IDNumber)
	if err != nil {
		return nil, fmt.Errorf("find criminal record: %w", err)
	}

	status, note, message, isVerified := resolveStatus(record)

	if status == StatusPassed {
		if !namesMatch(ocrResult.NameRaw, tech.FirstName, tech.LastName) {
			status = StatusPending
			isVerified = false
			note = fmt.Sprintf(
				"เลขบัตรผ่าน แต่ชื่อไม่ตรง — OCR: %q | ระบบ: %q",
				ocrResult.NameRaw, systemName,
			)
			message = "ชื่อในบัตรไม่ตรงกับชื่อในระบบ กรุณารอ admin ตรวจสอบ"
		}
	}

	_ = criminalRepo.SaveLog(&VerificationLog{
		TechnicianID: technicianID,
		NationalID:   ocrResult.IDNumber,
		Status:       status,
		Note:         note,
		RawOCRText:   rawOCRText,
	})

	if isVerified {
		_ = techRepo.UpdateVerificationStatus(ctx, technicianID, technician.StatusPassed)
	}

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
