package addressshared

import "strings"

func ParseAddressLineToStructured(addr *AddressFields) {

	if addr.AddressLine == nil {
		return
	}

	line := *addr.AddressLine

	if addr.HouseNumber == nil {
		addr.HouseNumber = extractHouseNumber(line)
	}

	if addr.Moo == nil {
		if strings.Contains(line, "หมู่บ้าน") {
		} else if strings.Contains(line, "หมู่") {
			addr.Moo = extractAfter(line, "หมู่")
		} else if strings.Contains(line, "ม.") {
			addr.Moo = extractAfter(line, "ม.")
		}
	}

	if addr.Village == nil {
		if strings.Contains(line, "หมู่บ้าน") {
			addr.Village = extractAfter(line, "หมู่บ้าน")
		}
	}

	if strings.Contains(line, "ซอย") && addr.Soi == nil {
		addr.Soi = extractAfter(line, "ซอย")
	} else if strings.Contains(line, "ซ.") && addr.Soi == nil {
		addr.Soi = extractAfter(line, "ซ.")
	}

	if strings.Contains(line, "ถนน") && addr.Road == nil {
		addr.Road = extractAfter(line, "ถนน")
	} else if strings.Contains(line, "ถ.") && addr.Road == nil {
		addr.Road = extractAfter(line, "ถ.")
	}

	if (strings.Contains(line, "ถนน") || strings.Contains(line, "ถ.")) && addr.Road == nil {
		addr.Road = extractAfter(line, "ถนน")
	}

}

func extractAfter(text, key string) *string {
	i := strings.Index(text, key)
	if i == -1 {
		return nil
	}

	s := strings.TrimSpace(text[i+len(key):])

	stopWords := []string{"หมู่", "ซอย", "ซ.", "ถนน", "ถ."}
	end := len(s)

	for _, w := range stopWords {
		if j := strings.Index(s, w); j != -1 && j < end {
			end = j
		}
	}

	val := strings.TrimSpace(s[:end])
	if val == "" {
		return nil
	}
	return &val
}

func extractHouseNumber(line string) *string {
	line = strings.TrimSpace(line)

	prefixes := []string{
		"บ้านเลขที่",
		"เลขที่",
		"บ้านเลขที่:",
		"เลขที่:",
	}

	for _, p := range prefixes {
		if strings.HasPrefix(line, p) {
			line = strings.TrimSpace(strings.TrimPrefix(line, p))
			break
		}
	}

	words := strings.Fields(line)

	for _, w := range words {
		if isHouseNumberToken(w) {
			v := w
			return &v
		}
	}
	return nil
}

func isHouseNumberToken(s string) bool {
	if s == "" {
		return false
	}

	hasDigit := false
	for _, r := range s {
		if r >= '0' && r <= '9' {
			hasDigit = true
			continue
		}
		if r == '/' || r == '-' {
			continue
		}
		return false
	}
	return hasDigit
}
