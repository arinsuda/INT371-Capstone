package customeraddresses

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"strings"

	"github.com/gofiber/fiber/v3"
)

func decodeJSON[T any](c fiber.Ctx, dst *T) error {
	body := c.Body()
	dec := json.NewDecoder(bytes.NewReader(body))
	dec.DisallowUnknownFields()

	if err := dec.Decode(dst); err != nil {
		switch e := err.(type) {
		case *json.SyntaxError:
			return fmt.Errorf("invalid JSON at byte %d", e.Offset)
		case *json.UnmarshalTypeError:
			field := e.Field
			if field == "" {
				field = "<root>"
			}
			return fmt.Errorf("field %q expects %s but got %s", field, e.Type.Kind(), e.Value)
		default:
			if ute := unknownFieldError(err); ute != "" {
				return fmt.Errorf(ute)
			}
			if err == io.EOF {
				return fmt.Errorf("empty body")
			}
			return err
		}
	}

	if dec.More() {
		return fmt.Errorf("body must contain a single JSON object")
	}
	return nil
}

func unknownFieldError(err error) string {
	const prefix = "json: unknown field "
	msg := err.Error()
	if strings.HasPrefix(msg, prefix) {
		return "unknown field " + strings.TrimPrefix(msg, prefix)
	}
	return ""
}
