package technician_badges

import "time"

type AssignBadgeDTO struct {
	TechnicianID uint       `json:"technician_id" validate:"required"`
	BadgeID      uint       `json:"badge_id" validate:"required"`
}

type RemoveBadgeDTO struct {
	ID         uint `json:"id" validate:"required"`
	HardDelete bool `json:"hard_delete,omitempty"`
}

type TechnicianBadgeResponse struct {
	ID           uint       `json:"id"`
	TechnicianID uint       `json:"technician_id"`
	BadgeID      uint       `json:"badge_id"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}
