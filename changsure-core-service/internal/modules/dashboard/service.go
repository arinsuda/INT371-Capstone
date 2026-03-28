package dashboard

import (
	"context"
	"fmt"
	"time"

	"changsure-core-service/pkg/storage"
)

type Service interface {
	GetDashboard(ctx context.Context, q DashboardQuery) (*DashboardResponse, error)
	GetPendingVerifications(ctx context.Context, q PendingVerificationQuery) (*PendingVerificationResponse, error)
	GetServicesByCategory(ctx context.Context, categoryID uint) (*CategoryServiceResponse, error)
	GetTechniciansByService(ctx context.Context, serviceID uint, q ServiceTechQuery) (*ServiceTechnicianResponse, error)
}

type service struct {
	repo    Repository
	storage storage.Storage
}

func NewService(repo Repository, store storage.Storage) Service {
	return &service{repo: repo, storage: store}
}

func (s *service) GetDashboard(ctx context.Context, q DashboardQuery) (*DashboardResponse, error) {
	q.SetDefaults()

	summary, err := s.repo.GetSummaryCards(ctx)
	if err != nil {
		return nil, fmt.Errorf("summary cards: %w", err)
	}

	catStats, err := s.repo.GetCategoryStats(ctx)
	if err != nil {
		return nil, fmt.Errorf("category stats: %w", err)
	}

	postWarning, err := s.repo.GetPostWarningSummary(ctx)
	if err != nil {
		return nil, fmt.Errorf("post warning: %w", err)
	}

	registrations, err := s.repo.GetRegistrationTrend(ctx, q.Days())
	if err != nil {
		return nil, fmt.Errorf("registrations: %w", err)
	}

	return &DashboardResponse{
		Summary:           *summary,
		CategoryStats:     catStats,
		PostWarning:       *postWarning,
		Registrations:     registrations,
		RegistrationRange: q.Range,
	}, nil
}

func (s *service) GetPendingVerifications(ctx context.Context, q PendingVerificationQuery) (*PendingVerificationResponse, error) {
	q.SetDefaults()

	items, total, err := s.repo.GetPendingVerifications(ctx, q.Page, q.PageSize)
	if err != nil {
		return nil, fmt.Errorf("pending verifications: %w", err)
	}

	return &PendingVerificationResponse{
		Items:    items,
		Total:    total,
		Page:     q.Page,
		PageSize: q.PageSize,
	}, nil
}

func (s *service) GetServicesByCategory(ctx context.Context, categoryID uint) (*CategoryServiceResponse, error) {
	return s.repo.GetServicesByCategory(ctx, categoryID)
}

func (s *service) GetTechniciansByService(ctx context.Context, serviceID uint, q ServiceTechQuery) (*ServiceTechnicianResponse, error) {
	q.SetDefaults()

	resp, err := s.repo.GetTechniciansByService(ctx, serviceID, q.Page, q.PageSize)
	if err != nil {
		return nil, fmt.Errorf("technicians by service: %w", err)
	}

	for i := range resp.Items {
		if resp.Items[i].AvatarURL != nil && *resp.Items[i].AvatarURL != "" {
			if signed, err := s.storage.PresignGet(ctx, *resp.Items[i].AvatarURL, time.Hour, false); err == nil {
				resp.Items[i].AvatarURL = &signed
			}
		}
	}

	return resp, nil
}
