package technicianbadge

import "time"

type AssignBadgeRequest struct {
	BadgeID   uint       `json:"badge_id" validate:"required"`
	ExpiredAt *time.Time `json:"expired_at"`
}

type BadgeInfo struct {
	ID          uint    `json:"id"`
	Name        string  `json:"name"`
	Level       uint    `json:"level"`
	Description *string `json:"description"`
	IconURL     *string `json:"icon_url"`
}

type TechnicianBadgeResponse struct {
	ID           uint      `json:"id"`
	TechnicianID uint      `json:"technician_id"`
	BadgeID      uint      `json:"badge_id"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
	Badge        BadgeInfo `json:"badge"`
}
