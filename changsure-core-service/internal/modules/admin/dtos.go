package admin

type SetupProfileRequest struct {
	AvatarURL *string `json:"avatar_url"`
	FirstName string  `json:"first_name" validate:"required,min=1,max=150"`
	LastName  string  `json:"last_name"  validate:"required,min=1,max=150"`
}

type UpdateAvatarRequest struct {
	AvatarKey string `json:"avatar_key" validate:"required"`
}

type UploadAvatarURLResponse struct {
	UploadURL string `json:"upload_url"`
	AvatarKey string `json:"avatar_key"`
}

type ProfileResponse struct {
	ID        uint    `json:"id"`
	AvatarURL *string `json:"avatar_url"`
	FirstName string  `json:"first_name"`
	LastName  string  `json:"last_name"`
	Email     string  `json:"email"`
}
