package badge

type CreateBadgeDTO struct {
	Name        string  `json:"name" validate:"required,min=2,max=100"`
	IconURL     *string `json:"icon_url" validate:"omitempty,url"`
	Level       *uint   `json:"level" validate:"omitempty,gte=0"`
	IsActive    *bool   `json:"is_active" validate:"omitempty"`
	Description *string `json:"description" validate:"omitempty,max=2000"`
}

type UpdateBadgeDTO struct {
	Name        *string `json:"name" validate:"omitempty,min=2,max=100"`
	IconURL     *string `json:"icon_url" validate:"omitempty,url"`
	Level       *uint   `json:"level" validate:"omitempty,gte=0"`
	IsActive    *bool   `json:"is_active" validate:"omitempty"`
	Description *string `json:"description" validate:"omitempty,max=2000"`
}

type ListBadgesQuery struct {
	Page    int    `query:"page"`
	PerPage int    `query:"per_page"`
	Search  string `query:"search"`
	Active  *bool  `query:"active"`
	Level   *uint  `query:"level"`

	IncludeDeleted bool `query:"include_deleted"`
	OnlyDeleted    bool `query:"only_deleted"`
}

type BadgeResponse struct {
	ID          uint   `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	IconURL     string `json:"icon_url"`
	Level       uint   `json:"level"`
	IsActive    bool   `json:"is_active"`
	CreatedAt   int64  `json:"created_at"`
	UpdatedAt   int64  `json:"updated_at"`
}
