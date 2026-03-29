package dashboard

import (
	"context"
	"math"
	"time"

	"gorm.io/gorm"
)

type Repository interface {
	GetSummaryCards(ctx context.Context) (*SummaryCards, error)
	GetCategoryStats(ctx context.Context) ([]CategoryStat, error)
	GetPostWarningSummary(ctx context.Context) (*PostWarningSummary, error)
	GetRegistrationTrend(ctx context.Context, days int) ([]RegistrationDay, error)
	GetPendingVerifications(ctx context.Context, page, pageSize int) ([]PendingVerificationItem, int64, error)
	GetServicesByCategory(ctx context.Context, categoryID uint) (*CategoryServiceResponse, error)
	GetTechniciansByService(ctx context.Context, serviceID uint, page, pageSize int) (*ServiceTechnicianResponse, error)
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &repository{db: db} }

func (r *repository) GetSummaryCards(ctx context.Context) (*SummaryCards, error) {
	var cards SummaryCards

	r.db.WithContext(ctx).Table("technicians").
		Where("deleted_at IS NULL").
		Count(&cards.TotalTechnicians)

	r.db.WithContext(ctx).Table("technicians").
		Where("deleted_at IS NULL AND verification_status = 'PENDING'").
		Count(&cards.PendingVerification)

	r.db.WithContext(ctx).Table("technicians").
		Where(`deleted_at IS NULL AND (
			SELECT COUNT(*) FROM technician_post_reports
			WHERE technician_id = technicians.id AND severity = 'WARNING'
		) >= 1`).
		Count(&cards.ReportedTechnicians)

	return &cards, nil
}

func (r *repository) GetCategoryStats(ctx context.Context) ([]CategoryStat, error) {
	type row struct {
		CategoryID   uint   `gorm:"column:category_id"`
		CategoryName string `gorm:"column:category_name"`
		Count        int64  `gorm:"column:count"`
	}
	var rows []row

	err := r.db.WithContext(ctx).
		Table("technician_services ts").
		Select("sc.id AS category_id, sc.cat_name AS category_name, COUNT(DISTINCT ts.technician_id) AS count").
		Joins("JOIN services s ON s.id = ts.service_id").
		Joins("JOIN service_categories sc ON sc.id = s.category_id").
		Where("ts.is_active = TRUE").
		Group("sc.id, sc.cat_name").
		Order("count DESC").
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}

	var total int64
	for _, r := range rows {
		total += r.Count
	}

	stats := make([]CategoryStat, 0, len(rows))
	for _, r := range rows {
		pct := 0.0
		if total > 0 {
			pct = math.Round(float64(r.Count)/float64(total)*1000) / 10
		}
		stats = append(stats, CategoryStat{
			CategoryID:   r.CategoryID,
			CategoryName: r.CategoryName,
			Count:        r.Count,
			Percentage:   pct,
		})
	}
	return stats, nil
}

func (r *repository) GetPostWarningSummary(ctx context.Context) (*PostWarningSummary, error) {
	type row struct {
		WarningCount int64 `gorm:"column:warning_count"`
		IsBanned     bool  `gorm:"column:is_banned"`
	}
	var rows []row

	err := r.db.WithContext(ctx).
		Table("technicians").
		Select(`
			(SELECT COUNT(*) FROM technician_post_reports
			 WHERE technician_id = technicians.id AND severity = 'WARNING') AS warning_count,
			(banned_at IS NOT NULL OR is_available = FALSE) AS is_banned
		`).
		Where("deleted_at IS NULL").
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}

	summary := &PostWarningSummary{}
	for _, r := range rows {
		switch {
		case r.IsBanned:
			summary.Banned++
		case r.WarningCount >= 1:
			summary.Warned++
		default:
			summary.Normal++
		}
	}
	return summary, nil
}

func (r *repository) GetRegistrationTrend(ctx context.Context, days int) ([]RegistrationDay, error) {
	type row struct {
		Date   string `gorm:"column:date"`
		Status string `gorm:"column:verification_status"`
		Count  int64  `gorm:"column:count"`
	}
	var rows []row

	cutoff := time.Now().AddDate(0, 0, -(days - 1))
	cutoffDate := cutoff.Format("2006-01-02")

	err := r.db.WithContext(ctx).
		Table("technicians").
		Select("DATE(created_at) AS date, verification_status, COUNT(*) AS count").
		Where("deleted_at IS NULL AND DATE(created_at) >= ?", cutoffDate).
		Group("DATE(created_at), verification_status").
		Order("date ASC").
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}

	type dayCounts struct {
		passed, pending, failed int64
	}
	dayMap := make(map[string]*dayCounts)

	for _, r := range rows {
		if _, ok := dayMap[r.Date]; !ok {
			dayMap[r.Date] = &dayCounts{}
		}
		switch r.Status {
		case "PASSED":
			dayMap[r.Date].passed += r.Count
		case "PENDING":
			dayMap[r.Date].pending += r.Count
		case "FAILED":
			dayMap[r.Date].failed += r.Count
		}
	}

	result := make([]RegistrationDay, 0, days)
	loc, _ := time.LoadLocation("Asia/Bangkok")
	for i := 0; i < days; i++ {
		d := cutoff.AddDate(0, 0, i)
		dateStr := d.Format("2006-01-02")
		dayName := d.In(loc).Weekday().String()[:3]

		counts := &dayCounts{}
		if c, ok := dayMap[dateStr]; ok {
			counts = c
		}
		result = append(result, RegistrationDay{
			Date:    dateStr,
			DayName: dayName,
			Passed:  counts.passed,
			Pending: counts.pending,
			Failed:  counts.failed,
			Total:   counts.passed + counts.pending + counts.failed,
		})
	}
	return result, nil
}

func (r *repository) GetPendingVerifications(ctx context.Context, page, pageSize int) ([]PendingVerificationItem, int64, error) {
	type row struct {
		Date  string `gorm:"column:date"`
		Count int64  `gorm:"column:count"`
	}
	var rows []row

	err := r.db.WithContext(ctx).
		Table("technicians").
		Select("DATE(created_at) AS date, COUNT(*) AS count").
		Where("deleted_at IS NULL AND verification_status = 'PENDING'").
		Group("DATE(created_at)").
		Order("date DESC").
		Scan(&rows).Error
	if err != nil {
		return nil, 0, err
	}

	total := int64(len(rows))
	offset := (page - 1) * pageSize

	type techRow struct {
		TechnicianID uint      `gorm:"column:id"`
		FirstName    string    `gorm:"column:first_name"`
		LastName     string    `gorm:"column:last_name"`
		Email        *string   `gorm:"column:email"`
		RegisteredAt time.Time `gorm:"column:created_at"`
		DateStr      string    `gorm:"column:date_str"`
	}

	var techRows []techRow
	err = r.db.WithContext(ctx).
		Table("technicians").
		Select(`
			id, first_name, last_name, email, created_at,
			DATE(created_at) AS date_str
		`).
		Where(`
			deleted_at IS NULL AND verification_status = 'PENDING'
			AND (id IN (
				SELECT MIN(id) FROM technicians
				WHERE deleted_at IS NULL AND verification_status = 'PENDING'
				GROUP BY DATE(created_at)
			))
		`).
		Order("created_at DESC").
		Limit(pageSize).
		Offset(offset).
		Scan(&techRows).Error
	if err != nil {
		return nil, 0, err
	}

	countMap := make(map[string]int64, len(rows))
	for _, r := range rows {
		countMap[r.Date] = r.Count
	}

	items := make([]PendingVerificationItem, 0, len(techRows))
	for _, t := range techRows {
		items = append(items, PendingVerificationItem{
			TechnicianID: t.TechnicianID,
			FirstName:    t.FirstName,
			LastName:     t.LastName,
			Email:        t.Email,
			RegisteredAt: t.RegisteredAt,
			PendingCount: countMap[t.DateStr],
		})
	}
	return items, total, nil
}

func (r *repository) GetServicesByCategory(ctx context.Context, categoryID uint) (*CategoryServiceResponse, error) {

	type catRow struct {
		ID      uint   `gorm:"column:id"`
		CatName string `gorm:"column:cat_name"`
	}
	var cat catRow
	if err := r.db.WithContext(ctx).
		Table("service_categories").
		Where("id = ?", categoryID).
		First(&cat).Error; err != nil {
		return nil, err
	}

	type row struct {
		ServiceID   uint   `gorm:"column:service_id"`
		ServiceName string `gorm:"column:service_name"`
		TechCount   int64  `gorm:"column:tech_count"`
	}
	var rows []row

	err := r.db.WithContext(ctx).
		Table("services s").
		Select("s.id AS service_id, s.ser_name AS service_name, COUNT(DISTINCT ts.technician_id) AS tech_count").
		Joins("LEFT JOIN technician_services ts ON ts.service_id = s.id AND ts.is_active = TRUE").
		Where("s.category_id = ?", categoryID).
		Group("s.id, s.ser_name").
		Order("tech_count DESC").
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}

	items := make([]ServiceInCategoryItem, 0, len(rows))
	for _, r := range rows {
		items = append(items, ServiceInCategoryItem{
			ServiceID:   r.ServiceID,
			ServiceName: r.ServiceName,
			TechCount:   r.TechCount,
		})
	}

	return &CategoryServiceResponse{
		CategoryID:   cat.ID,
		CategoryName: cat.CatName,
		Services:     items,
	}, nil
}

func (r *repository) GetTechniciansByService(ctx context.Context, serviceID uint, page, pageSize int) (*ServiceTechnicianResponse, error) {

	type svcRow struct {
		ID      uint   `gorm:"column:id"`
		SerName string `gorm:"column:ser_name"`
	}
	var svc svcRow
	if err := r.db.WithContext(ctx).
		Table("services").
		Where("id = ?", serviceID).
		First(&svc).Error; err != nil {
		return nil, err
	}

	type row struct {
		TechnicianID uint    `gorm:"column:id"`
		FirstName    string  `gorm:"column:first_name"`
		LastName     string  `gorm:"column:last_name"`
		AvatarURL    *string `gorm:"column:avatar_url"`
		RatingAvg    float64 `gorm:"column:rating_avg"`
		TotalJobs    int64   `gorm:"column:total_jobs"`
		IsAvailable  bool    `gorm:"column:is_available"`
	}

	var total int64
	r.db.WithContext(ctx).
		Table("technician_services ts").
		Joins("JOIN technicians t ON t.id = ts.technician_id").
		Where("ts.service_id = ? AND ts.is_active = TRUE AND t.deleted_at IS NULL", serviceID).
		Count(&total)

	var rows []row
	err := r.db.WithContext(ctx).
		Table("technician_services ts").
		Select(`
        t.id, 
        t.first_name, 
        t.last_name, 
        t.avatar_url, 
        COALESCE(ts2.rating_avg, 0) AS rating_avg,
        COALESCE(ts2.total_jobs, 0) AS total_jobs,
        t.is_available
    `).
		Joins("JOIN technicians t ON t.id = ts.technician_id").
		Joins("LEFT JOIN technician_stats ts2 ON ts2.technician_id = t.id").
		Where("ts.service_id = ? AND ts.is_active = TRUE AND t.deleted_at IS NULL", serviceID).
		Order("rating_avg DESC").
		Limit(pageSize).
		Offset((page - 1) * pageSize).
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}

	items := make([]TechnicianInServiceItem, 0, len(rows))
	for _, r := range rows {
		items = append(items, TechnicianInServiceItem{
			TechnicianID: r.TechnicianID,
			FirstName:    r.FirstName,
			LastName:     r.LastName,
			AvatarURL:    r.AvatarURL,
			RatingAvg:    r.RatingAvg,
			TotalJobs:    r.TotalJobs,
			IsAvailable:  r.IsAvailable,
		})
	}

	return &ServiceTechnicianResponse{
		ServiceID:   svc.ID,
		ServiceName: svc.SerName,
		Items:       items,
		Total:       total,
		Page:        page,
		PageSize:    pageSize,
	}, nil
}
