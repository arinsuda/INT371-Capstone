package service

import (
	"changsure-core-service/pkg/storage"
	"context"
	"time"
)

type ServiceSvc interface {
	Create(ctx context.Context, in CreateServiceRequest) (uint, error)
	Update(ctx context.Context, id uint, in UpdateServiceRequest) error
	Get(ctx context.Context, id uint) (*Service, error)
	List(ctx context.Context, q ListQuery) ([]Service, int64, error)
	Delete(ctx context.Context, id uint) error

	GetAllServiceNoPagination(ctx context.Context, q ListQuery) ([]Service, error)
	GetServicesForMenu(ctx context.Context, q ListMenuQuery) ([]ServiceMenuResponse, error)
	GetMenu(ctx context.Context, q MenuQuery) ([]CategoryMenuGroup, error)
	GetMenuDetail(ctx context.Context, id uint, provinceID uint) (*ServiceMenuDetail, error)
}

type service struct{ repo Repository }

func NewService(repo Repository) ServiceSvc { return &service{repo: repo} }

func (s *service) Create(ctx context.Context, in CreateServiceRequest) (uint, error) {
	m := &Service{
		CategoryID:      in.CategoryID,
		SerName:         in.SerName,
		SerDescription:  in.SerDescription,
		SerDetails:      in.SerDetails,
		AdditionalTerms: in.AdditionalTerms,
		WorkingDuration: in.WorkingDuration,
		ImageURLs:       in.ImageURLs,
		IsActive:        true,
		DefaultPrice:    in.DefaultPrice,
	}

	if in.IsActive != nil {
		m.IsActive = *in.IsActive
	}

	if err := s.repo.Create(ctx, m); err != nil {
		return 0, err
	}
	return m.ID, nil
}

func (s *service) Update(ctx context.Context, id uint, in UpdateServiceRequest) error {
	fields := map[string]any{}

	if in.CategoryID != nil {
		fields["category_id"] = *in.CategoryID
	}
	if in.SerName != nil {
		fields["ser_name"] = *in.SerName
	}

	if in.SerDescription != nil {
		fields["ser_description"] = *in.SerDescription
	}
	if in.SerDetails != nil {
		fields["ser_details"] = *in.SerDetails
	}
	if in.AdditionalTerms != nil {
		fields["additional_terms"] = *in.AdditionalTerms
	}
	if in.WorkingDuration != nil {
		fields["working_duration"] = *in.WorkingDuration
	}

	if in.ImageURLs != nil {
		fields["image_url"] = *in.ImageURLs
	}
	if in.IsActive != nil {
		fields["is_active"] = *in.IsActive
	}

	if len(fields) == 0 {
		return nil
	}

	return s.repo.UpdateFields(ctx, id, fields)
}

func (s *service) Get(ctx context.Context, id uint) (*Service, error) {
	return s.repo.Get(ctx, id)
}

func (s *service) GetAllServiceNoPagination(ctx context.Context, q ListQuery) ([]Service, error) {
	q.SortBy = "id"
	q.SortOrder = "asc"

	return s.repo.GetAll(ctx, q)
}

func (s *service) List(ctx context.Context, q ListQuery) ([]Service, int64, error) {
	return s.repo.List(ctx, q)
}

func (s *service) Delete(ctx context.Context, id uint) error {
	return s.repo.Delete(ctx, id)
}

func (s *service) GetServicesForMenu(ctx context.Context, q ListMenuQuery) ([]ServiceMenuResponse, error) {

	listQ := ListQuery{
		CategoryID: q.CategoryID,
		IsActive:   q.IsActive,
	}
	items, err := s.repo.GetAll(ctx, listQ)
	if err != nil {
		return nil, err
	}
	if len(items) == 0 {
		return []ServiceMenuResponse{}, nil
	}

	serviceIDs := make([]uint, 0, len(items))
	for _, it := range items {
		serviceIDs = append(serviceIDs, it.ID)
	}

	techPrices, err := s.repo.GetPriceRangeByProvince(ctx, serviceIDs, q.ProvinceID)
	if err != nil {
		return nil, err
	}

	result := make([]ServiceMenuResponse, 0, len(items))
	for _, it := range items {
		resp := buildMenuResponse(&it, techPrices[it.ID])
		result = append(result, resp)
	}

	return result, nil
}

func buildMenuResponse(m *Service, techPrice PriceRange) ServiceMenuResponse {
	resp := ServiceMenuResponse{
		ID:             m.ID,
		SerName:        m.SerName,
		SerDescription: m.SerDescription,
		IsActive:       m.IsActive,
		CategoryID:     m.CategoryID,
	}

	if m.Category != nil {
		resp.CategoryName = &m.Category.CatName
	}

	if techPrice.Min > 0 {
		pr := MenuPriceRange{Min: techPrice.Min}
		if techPrice.Max > techPrice.Min {
			pr.Max = &techPrice.Max
		}
		resp.Price = pr
		resp.PriceSource = "technician"
	} else {

		resp.Price = extractDefaultPrice(m.DefaultPrice)
		resp.PriceSource = "default"
	}

	return resp
}

func extractDefaultPrice(dp map[string]interface{}) MenuPriceRange {
	if dp == nil {
		return MenuPriceRange{}
	}

	priceType, _ := dp["type"].(string)

	toFloat := func(v interface{}) float64 {
		switch n := v.(type) {
		case float64:
			return n
		case int:
			return float64(n)
		}
		return 0
	}

	switch priceType {
	case "fixed":
		val := toFloat(dp["value"])
		return MenuPriceRange{Min: val}
	case "range":
		min := toFloat(dp["min"])
		pr := MenuPriceRange{Min: min}
		if maxVal, ok := dp["max"]; ok {
			m := toFloat(maxVal)
			if m > min {
				pr.Max = &m
			}
		}
		return pr
	default:

		min := toFloat(dp["min"])
		return MenuPriceRange{Min: min}
	}
}

func (s *service) GetMenu(ctx context.Context, q MenuQuery) ([]CategoryMenuGroup, error) {
	// 1. ดึง services ทั้งหมด
	listQ := ListQuery{CategoryID: q.CategoryID, IsActive: q.IsActive}
	items, err := s.repo.GetAll(ctx, listQ)
	if err != nil {
		return nil, err
	}
	if len(items) == 0 {
		return []CategoryMenuGroup{}, nil
	}

	// 2. batch query ราคา + จำนวนช่าง (1 query)
	ids := make([]uint, len(items))
	for i, it := range items {
		ids[i] = it.ID
	}
	techMap, err := s.repo.GetPriceAndCountByProvince(ctx, ids, q.ProvinceID)
	if err != nil {
		return nil, err
	}

	// 3. group by category
	groupMap := make(map[uint]*CategoryMenuGroup)
	groupOrder := []uint{}

	presign := func(key string) string {
		u, err := storage.GlobalMinio.PresignGet(context.Background(), key, time.Hour, false)
		if err != nil {
			return key
		}
		return u
	}

	for i := range items {
		it := &items[i]
		td, hasTech := techMap[it.ID]
		var tdPtr *PriceAndCount
		if hasTech {
			tdPtr = &td
		}

		card := MapToServiceMenuCard(it, tdPtr, presign)

		if _, exists := groupMap[it.CategoryID]; !exists {
			var catName string
			var catIcon *string
			if it.Category != nil {
				catName = it.Category.CatName
				if it.Category.IconURL != nil && *it.Category.IconURL != "" {
					u := presign(*it.Category.IconURL)
					catIcon = &u
				}
			}
			groupMap[it.CategoryID] = &CategoryMenuGroup{
				CategoryID:   it.CategoryID,
				CategoryName: catName,
				CategoryIcon: catIcon,
				Services:     []ServiceMenuCard{},
			}
			groupOrder = append(groupOrder, it.CategoryID)
		}
		groupMap[it.CategoryID].Services = append(groupMap[it.CategoryID].Services, card)
	}

	// 4. คง order ตาม category
	result := make([]CategoryMenuGroup, 0, len(groupOrder))
	for _, catID := range groupOrder {
		result = append(result, *groupMap[catID])
	}
	return result, nil
}

func (s *service) GetMenuDetail(ctx context.Context, id uint, provinceID uint) (*ServiceMenuDetail, error) {
	m, err := s.repo.Get(ctx, id)
	if err != nil {
		return nil, err
	}

	techMap, err := s.repo.GetPriceAndCountByProvince(ctx, []uint{id}, provinceID)
	if err != nil {
		return nil, err
	}

	presign := func(key string) string {
		u, err := storage.GlobalMinio.PresignGet(context.Background(), key, time.Hour, false)
		if err != nil {
			return key
		}
		return u
	}

	td, hasTech := techMap[id]
	var tdPtr *PriceAndCount
	if hasTech {
		tdPtr = &td
	}

	detail := MapToServiceMenuDetail(m, tdPtr, presign)
	return &detail, nil
}
