package customerreview

import "fmt"

type CreateReviewRequest struct {
	Rating    int8     `json:"rating" form:"rating" validate:"required,min=1,max=5"`
	Comment   string   `json:"comment" form:"comment" validate:"omitempty,max=500"`
	ImageURLs []string `json:"image_urls" form:"-" validate:"omitempty,max=5"`
}

func (r *CreateReviewRequest) Validate() error {
	if r.Rating < 1 || r.Rating > 5 {
		return fmt.Errorf("rating must be between 1 and 5")
	}
	if len(r.ImageURLs) > 5 {
		return fmt.Errorf("maximum 5 images allowed")
	}
	return nil
}
