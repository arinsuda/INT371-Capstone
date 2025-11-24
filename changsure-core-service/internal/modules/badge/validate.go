package badge

import (
	"errors"
	"strings"

	"github.com/go-playground/validator/v10"
)

var validate *validator.Validate

func init() {
	validate = validator.New()

}

func ValidateStruct(v any) error {
	if err := validate.Struct(v); err != nil {
		return formatValidationError(err)
	}
	return nil
}

func formatValidationError(err error) error {
	var verrs validator.ValidationErrors
	if errors.As(err, &verrs) {
		msgs := make([]string, 0, len(verrs))
		for _, fe := range verrs {
			field := fe.Field()
			tag := fe.Tag()
			switch tag {
			case "required":
				msgs = append(msgs, strings.ToLower(field)+" is required")
			case "url":
				msgs = append(msgs, strings.ToLower(field)+" must be a valid url")
			case "min":
				msgs = append(msgs, strings.ToLower(field)+" is too short")
			case "max":
				msgs = append(msgs, strings.ToLower(field)+" is too long")
			case "gte":
				msgs = append(msgs, strings.ToLower(field)+" must be greater or equal")
			default:
				msgs = append(msgs, field+" is invalid ("+tag+")")
			}
		}
		return errors.New(strings.Join(msgs, "; "))
	}
	return err
}
