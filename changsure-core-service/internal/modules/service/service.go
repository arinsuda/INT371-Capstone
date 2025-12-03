package service

import "context"

type ServiceSvc interface {
	Create(ctx context.Context, in CreateServiceRequest) (uint, error)
	Update(ctx context.Context, id uint, in UpdateServiceRequest) error
	Get(ctx context.Context, id uint) (*Service, error)
	List(ctx context.Context, q ListQuery) ([]Service, int64, error)
	Delete(ctx context.Context, id uint) error
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

func (s *service) List(ctx context.Context, q ListQuery) ([]Service, int64, error) {
	return s.repo.List(ctx, q)
}

func (s *service) Delete(ctx context.Context, id uint) error {
	return s.repo.Delete(ctx, id)
}
