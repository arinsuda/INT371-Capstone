package criminalcheck

import (
	"errors"
	"time"

	"gorm.io/gorm"
)

type Repository interface {
	FindByNationalID(nationalID string) (*MockCriminalRecord, error)
	SaveLog(log *VerificationLog) error

	ListLogs(filter ListLogsFilter) ([]VerificationLog, int64, error)
	GetLogsByTechnicianID(technicianID uint) ([]VerificationLog, error)
	GetLogByID(logID uint) (*VerificationLog, error)
	UpdateLogStatus(logID uint, status CheckStatus, note string) error

	SaveOverrideLog(log *AdminOverrideLog) error
	GetOverrideHistory(targetType string, targetID uint) ([]AdminOverrideLog, error)

	GetStats() (*VerificationStatResponse, error)

	ListCriminalRecords(page, pageSize int, status string) ([]MockCriminalRecord, int64, error)
	GetCriminalRecordByID(id uint) (*MockCriminalRecord, error)
	GetCriminalRecordByNationalID(nationalID string) (*MockCriminalRecord, error)
	CreateCriminalRecord(record *MockCriminalRecord) error
	UpdateCriminalRecord(id uint, updates map[string]interface{}) error
	DeleteCriminalRecord(id uint) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindByNationalID(nationalID string) (*MockCriminalRecord, error) {
	var record MockCriminalRecord
	err := r.db.Where("national_id = ?", nationalID).First(&record).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &record, err
}

func (r *repository) SaveLog(log *VerificationLog) error {
	return r.db.Create(log).Error
}

func (r *repository) ListLogs(f ListLogsFilter) ([]VerificationLog, int64, error) {
	if f.Page < 1 {
		f.Page = 1
	}
	if f.PageSize < 1 || f.PageSize > 100 {
		f.PageSize = 20
	}
	offset := (f.Page - 1) * f.PageSize

	q := r.db.Model(&VerificationLog{})

	if f.Status != "" {
		q = q.Where("status = ?", f.Status)
	}
	if f.NationalID != "" {
		q = q.Where("national_id LIKE ?", "%"+f.NationalID+"%")
	}
	if f.DateFrom != "" {
		if t, err := time.Parse("2006-01-02", f.DateFrom); err == nil {
			q = q.Where("created_at >= ?", t)
		}
	}
	if f.DateTo != "" {
		if t, err := time.Parse("2006-01-02", f.DateTo); err == nil {
			q = q.Where("created_at <= ?", t.Add(24*time.Hour))
		}
	}
	if f.TechName != "" {
		q = q.Joins("JOIN technicians ON technicians.id = verification_logs.technician_id").
			Where("CONCAT(technicians.firstname, ' ', technicians.lastname) LIKE ?", "%"+f.TechName+"%")
	}

	var total int64
	q.Count(&total)

	var logs []VerificationLog
	err := q.Order("created_at DESC").Limit(f.PageSize).Offset(offset).Find(&logs).Error
	return logs, total, err
}

func (r *repository) GetLogsByTechnicianID(technicianID uint) ([]VerificationLog, error) {
	var logs []VerificationLog
	err := r.db.Where("technician_id = ?", technicianID).
		Order("created_at DESC").
		Find(&logs).Error
	return logs, err
}

func (r *repository) GetLogByID(logID uint) (*VerificationLog, error) {
	var log VerificationLog
	if err := r.db.First(&log, logID).Error; err != nil {
		return nil, err
	}
	return &log, nil
}

func (r *repository) UpdateLogStatus(logID uint, status CheckStatus, note string) error {
	return r.db.Model(&VerificationLog{}).
		Where("id = ?", logID).
		Updates(map[string]interface{}{"status": status, "note": note}).Error
}

func (r *repository) SaveOverrideLog(log *AdminOverrideLog) error {
	return r.db.Create(log).Error
}

func (r *repository) GetOverrideHistory(targetType string, targetID uint) ([]AdminOverrideLog, error) {
	var logs []AdminOverrideLog
	err := r.db.Where("target_type = ? AND target_id = ?", targetType, targetID).
		Order("created_at DESC").
		Find(&logs).Error
	return logs, err
}

func (r *repository) GetStats() (*VerificationStatResponse, error) {
	var stats VerificationStatResponse
	r.db.Model(&VerificationLog{}).Count(&stats.Total)
	r.db.Model(&VerificationLog{}).Where("status = ?", StatusPassed).Count(&stats.Passed)
	r.db.Model(&VerificationLog{}).Where("status = ?", StatusFailed).Count(&stats.Failed)
	r.db.Model(&VerificationLog{}).Where("status = ?", StatusPending).Count(&stats.Pending)
	r.db.Model(&VerificationLog{}).Where("status = ?", StatusNotFound).Count(&stats.NotFound)
	return &stats, nil
}

func (r *repository) ListCriminalRecords(page, pageSize int, status string) ([]MockCriminalRecord, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	q := r.db.Model(&MockCriminalRecord{})
	if status != "" {
		q = q.Where("status = ?", status)
	}

	var total int64
	q.Count(&total)

	var records []MockCriminalRecord
	err := q.Order("created_at DESC").Limit(pageSize).Offset(offset).Find(&records).Error
	return records, total, err
}

func (r *repository) GetCriminalRecordByID(id uint) (*MockCriminalRecord, error) {
	var record MockCriminalRecord
	if err := r.db.First(&record, id).Error; err != nil {
		return nil, err
	}
	return &record, nil
}

func (r *repository) GetCriminalRecordByNationalID(nationalID string) (*MockCriminalRecord, error) {
	var record MockCriminalRecord
	err := r.db.Where("national_id = ?", nationalID).First(&record).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &record, err
}

func (r *repository) CreateCriminalRecord(record *MockCriminalRecord) error {
	return r.db.Create(record).Error
}

func (r *repository) UpdateCriminalRecord(id uint, updates map[string]interface{}) error {
	return r.db.Model(&MockCriminalRecord{}).Where("id = ?", id).Updates(updates).Error
}

func (r *repository) DeleteCriminalRecord(id uint) error {
	return r.db.Delete(&MockCriminalRecord{}, id).Error
}
