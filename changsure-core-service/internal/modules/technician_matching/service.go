package technicianmatching

import (
	"changsure-core-service/pkg/storage"
	"context"
	"errors"
	"time"
)

type Service interface {
	ListTechnicians(ctx context.Context, customerID uint, q TechnicianSearchQuery) ([]TechnicianListItem, int64, error)
	GetTechnicianDetail(ctx context.Context, id uint) (*TechnicianDetail, error)
	AutoSelectTechnician(ctx context.Context, customerID uint, req AutoSelectRequest) (*TechnicianListItem, error)
}

type service struct {
	repo    Repository
	storage storage.Storage
}

func NewService(repo Repository, s storage.Storage) Service {
	return &service{
		repo:    repo,
		storage: s,
	}
}

func (s *service) ListTechnicians(ctx context.Context, customerID uint, q TechnicianSearchQuery) ([]TechnicianListItem, int64, error) {

	custLat, custLng, err := s.repo.GetCustomerPrimaryAddress(ctx, customerID)
	if err != nil {
		return nil, 0, errors.New("customer has no primary address")
	}

	techsWithDist, total, err := s.repo.SearchTechnicians(ctx, custLat, custLng, q)
	if err != nil {
		return nil, 0, err
	}

	items := make([]TechnicianListItem, 0)
	for _, t := range techsWithDist {

		distKm := t.DistanceMeters / 1000.0

		signedAvatar := ""
		if t.AvatarURL != nil && *t.AvatarURL != "" {
			url, err := s.storage.PresignGet(ctx, *t.AvatarURL, 15*time.Minute, false)
			if err == nil {
				signedAvatar = url
			}
		}

		badgeList := make([]BadgeResponse, 0)
		for _, b := range t.Badges {

			signedIcon := ""
			if b.Badge.IconURL != "" {
				url, err := s.storage.PresignGet(ctx, b.Badge.IconURL, 15*time.Minute, false)
				if err == nil {
					signedIcon = url
				}
			}

			badgeList = append(badgeList, BadgeResponse{
				ID:          b.Badge.ID,
				Name:        b.Badge.Name,
				Description: b.Badge.Description,
				IconURL:     signedIcon,
				Level:       int(b.Badge.Level),
				IsActive:    b.Badge.IsActive,
				CreatedAt:   b.Badge.CreatedAt.Unix(),
				UpdatedAt:   b.Badge.UpdatedAt.Unix(),
			})
		}

		item := MapTechnicianToListItem(&t.Technician, distKm, signedAvatar, badgeList, q.ServiceID)
		items = append(items, item)
	}

	return items, total, nil
}

func (s *service) GetTechnicianDetail(ctx context.Context, id uint) (*TechnicianDetail, error) {
	t, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	signedAvatar := ""
	if t.AvatarURL != nil && *t.AvatarURL != "" {
		url, err := s.storage.PresignGet(ctx, *t.AvatarURL, 15*time.Minute, false)
		if err == nil {
			signedAvatar = url
		}
	}

	badgeList := make([]BadgeResponse, 0)
	for _, b := range t.Badges {

		signedIcon := ""
		if b.Badge.IconURL != "" {
			url, err := s.storage.PresignGet(ctx, b.Badge.IconURL, 15*time.Minute, false)
			if err == nil {
				signedIcon = url
			}
		}

		badgeList = append(badgeList, BadgeResponse{
			ID:          b.Badge.ID,
			Name:        b.Badge.Name,
			Description: b.Badge.Description,
			IconURL:     signedIcon,
			Level:       int(b.Badge.Level),
			IsActive:    b.Badge.IsActive,
			CreatedAt:   b.Badge.CreatedAt.Unix(),
			UpdatedAt:   b.Badge.UpdatedAt.Unix(),
		})
	}

	res := MapTechnicianToDetail(t, signedAvatar, badgeList)
	return &res, nil
}

func (s *service) AutoSelectTechnician(ctx context.Context, customerID uint, req AutoSelectRequest) (*TechnicianListItem, error) {
	// 1. เตรียม Query Filter (Hard Filters)
	// ส่งค่าทุกอย่างที่รับมา ไปให้ Repository กรองออกจาก DB เลย
	q := TechnicianSearchQuery{
		ServiceID:  &req.ServiceID,
		ProvinceID: &req.ProvinceID,

		// Map ค่าละเอียด
		MinPrice:  req.MinPrice,
		MaxPrice:  req.MaxPrice,
		MinRating: req.MinRating,
		Sort:      "dist_asc", // ดึงคนที่ใกล้ที่สุดมาก่อน เพื่อมาคำนวณคะแนน

		// ถ้า Repository คุณรองรับ Search ก็ map ไปด้วยได้
		// Search: req.Search,

		Page:     1,
		PageSize: 100, // ดึงมาพิจารณาสัก 100 คน (ที่ผ่านเกณฑ์แล้ว)
	}

	// 2. ดึงข้อมูล (คนที่ไม่ผ่าน Min/Max Price หรือ Min Rating จะไม่หลุดมาใน list นี้)
	list, _, err := s.ListTechnicians(ctx, customerID, q)
	if err != nil {
		return nil, err
	}

	// ถ้ากรองแล้วไม่เหลือใครเลย
	if len(list) == 0 {
		return nil, nil
	}

	// 3. คำนวณคะแนนความแมตช์ (Soft Selection)
	// เพื่อหาว่าในบรรดาคนที่ "ผ่านเกณฑ์" ใครคือคนที่ "ดีที่สุด" ตาม Priority
	scoredList := CalculateMatchScore(list, req.Priority)

	// 4. เลือกคนที่คะแนนเยอะที่สุด
	best := PickBestTechnician(scoredList)

	return best, nil
}
