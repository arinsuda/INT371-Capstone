package notification

type CreateNotificationInput struct {
	RecipientRole RecipientRole  `json:"recipient_role" validate:"required"`
	RecipientID   uint           `json:"recipient_id" validate:"required"`
	Type          string         `json:"type" validate:"required,max=64"`
	Title         string         `json:"title" validate:"required,max=255"`
	Message       string         `json:"message" validate:"required"`
	EntityType    string         `json:"entity_type" validate:"omitempty,max=32"`
	EntityID      uint           `json:"entity_id"`
	Data          map[string]any `json:"data"`
}

type ListQuery struct {
	Limit      int  `query:"limit"`
	Cursor     uint `query:"cursor"`
	UnreadOnly bool `query:"unread_only"`
}

type MarkReadRequest struct {
	IDs []uint `json:"ids" validate:"required,min=1,dive,gt=0"`
}
