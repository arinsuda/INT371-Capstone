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
	IsVerified    bool
}

func ProcessVerification(
	ctx context.Context,
	technicianID uint,
	ocrItems []infra.OCRItem,
	criminalRepo Repository,
	techRepo technician.Repository,
) (*VerificationResult, error) {

	var rawTexts []string
	for _, item := range ocrItems {
		rawTexts = append(rawTexts, item.Text)
	}
	rawOCRText := strings.Join(rawTexts, " ")

	nationalID, idCardY := extractNationalIDWithY(ocrItems)
	if nationalID == "" {
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

	extractedName := extractThaiName(ocrItems, idCardY)
	if extractedName == "" {
		_ = criminalRepo.SaveLog(&VerificationLog{
			TechnicianID: technicianID,
			NationalID:   nationalID,
			Status:       StatusNameNotExtracted,
			Note:         "อ่านเลขบัตรได้ แต่ไม่สามารถ extract ชื่อจากรูปภาพได้",
			RawOCRText:   rawOCRText,
		})
		return &VerificationResult{
			TechnicianID: technicianID,
			NationalID:   nationalID,
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

	record, err := criminalRepo.FindByNationalID(nationalID)
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

	_ = criminalRepo.SaveLog(&VerificationLog{
		TechnicianID: technicianID,
		NationalID:   nationalID,
		Status:       status,
		Note:         note,
		RawOCRText:   rawOCRText,
	})

	if isVerified {
		tech.IsVerified = true
		_ = techRepo.Update(ctx, tech)
	}

	return &VerificationResult{
		TechnicianID:  technicianID,
		NationalID:    nationalID,
		ExtractedName: extractedName,
		SystemName:    systemName,
		Status:        status,
		Note:          note,
		Message:       message,
		IsVerified:    isVerified,
	}, nil
}
