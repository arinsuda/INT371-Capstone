package customertechnician

import (
	"context"

	tsa "changsure-core-service/internal/modules/technician_service_area"
	ts "changsure-core-service/internal/modules/technician_service"
	"changsure-core-service/internal/modules/technician"
)

/*
==========================================================
 SERVICE INTERFACE
==========================================================
*/

type Service interface {
	List(ctx context.Context, q TechnicianListQuery) ([]TechnicianListItem, error)
	GetByID(ctx context.Context, id uint) (*TechnicianDetail, error)
	AutoSelect(ctx context.Context, req AutoSelectRequest) (*TechnicianListItem, error)
}

/*
==========================================================
 SERVICE IMPLEMENTATION + DEPENDENCIES
==========================================================
*/

type service struct {
	repo     Repository
	techRepo technician.Repository
	svcRepo  ts.Repository
	areaRepo tsa.Repository
}

func NewService(
	repo Repository,
	tech technician.Repository,
	svc ts.Repository,
	area tsa.Repository,
) Service {
	return &service{
		repo:     repo,
		techRepo: tech,
		svcRepo:  svc,
		areaRepo: area,
	}
}

/*
==========================================================
 LIST TECHNICIANS
==========================================================
*/

func (s *service) List(ctx context.Context, q TechnicianListQuery) ([]TechnicianListItem, error) {

	techs, err := s.repo.List(ctx, q)
	if err != nil {
		return nil, err
	}

	result := make([]TechnicianListItem, 0, len(techs))

	for _, t := range techs {
		result = append(result, mapToListItem(&t))
	}

	return result, nil
}

/*
==========================================================
 GET TECHNICIAN DETAIL
==========================================================
*/

func (s *service) GetByID(ctx context.Context, id uint) (*TechnicianDetail, error) {

	t, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}

	res := mapToDetail(t)
	return &res, nil
}

/*
==========================================================
 AUTO-SELECT (BEST MATCH)
==========================================================
*/

func (s *service) AutoSelect(ctx context.Context, req AutoSelectRequest) (*TechnicianListItem, error) {

	q := TechnicianListQuery{
		ServiceID:  &req.ServiceID,
		ProvinceID: &req.ProvinceID,
	}

	techs, err := s.repo.List(ctx, q)
	if err != nil {
		return nil, err
	}

	if len(techs) == 0 {
		return nil, nil
	}

	best := pickBestTechnician(techs, req.Priority)
	if best == nil {
		return nil, nil
	}

	item := mapToListItem(best)
	return &item, nil
}
