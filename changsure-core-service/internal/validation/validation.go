package validation

import (
	"reflect"
	"regexp"

	"github.com/go-playground/locales/en"
	"github.com/go-playground/locales/th"
	ut "github.com/go-playground/universal-translator"
	"github.com/go-playground/validator/v10"
	enTranslations "github.com/go-playground/validator/v10/translations/en"
	thTranslations "github.com/go-playground/validator/v10/translations/th"
)

var (
	V *validator.Validate
	T ut.Translator
)

type FieldError struct {
	Field string `json:"field"`
	Error string `json:"error"`
}

func Init(locale string) error {
	V = validator.New(validator.WithRequiredStructEnabled())

	V.RegisterTagNameFunc(func(fld reflect.StructField) string {
		tag := fld.Tag.Get("json")
		if tag == "-" || tag == "" {
			return fld.Name
		}
		for i, c := range tag {
			if c == ',' {
				return tag[:i]
			}
		}
		return tag
	})

	_ = V.RegisterValidation("th_postal", func(fl validator.FieldLevel) bool {
		return regexp.MustCompile(`^\d{5}$`).MatchString(fl.Field().String())
	})
	_ = V.RegisterValidation("lat", func(fl validator.FieldLevel) bool {
		v, ok := fl.Field().Interface().(float64)
		return ok && v >= -90 && v <= 90
	})
	_ = V.RegisterValidation("lon", func(fl validator.FieldLevel) bool {
		v, ok := fl.Field().Interface().(float64)
		return ok && v >= -180 && v <= 180
	})

	uni := ut.New(en.New(), en.New(), th.New())
	trans, _ := uni.GetTranslator(locale)
	switch locale {
	case "th":
		_ = thTranslations.RegisterDefaultTranslations(V, trans)
	default:
		_ = enTranslations.RegisterDefaultTranslations(V, trans)
	}
	T = trans
	return nil
}

// ValidateStruct เรียกใช้ในทุกโมดูล
func ValidateStruct(s any) ([]FieldError, error) {
	if err := V.Struct(s); err != nil {
		if verrs, ok := err.(validator.ValidationErrors); ok {
			out := make([]FieldError, 0, len(verrs))
			for _, ve := range verrs {
				msg := ve.Error()
				if T != nil {
					msg = ve.Translate(T)
				}
				out = append(out, FieldError{
					Field: ve.Field(),
					Error: msg,
				})
			}
			return out, err
		}
		return []FieldError{{Field: "", Error: err.Error()}}, err
	}
	return nil, nil
}
