package criminalcheck

import (
	"strings"
)

func normalizeThaiName(name string) string {
	prefixes := []string{"นาย", "นาง", "น.ส.", "นางสาว", "ด.ช.", "ด.ญ."}
	name = strings.TrimSpace(name)
	for _, p := range prefixes {
		name = strings.TrimPrefix(name, p)
	}
	name = strings.ReplaceAll(name, " ", "")
	return strings.TrimSpace(name)
}

func namesMatch(ocrName, systemFirstName, systemLastName string) bool {
	if ocrName == "" {
		return false
	}

	normalizedOCR := normalizeThaiName(ocrName)
	systemFull := normalizeThaiName(systemFirstName + systemLastName)

	if normalizedOCR == systemFull {
		return true
	}

	normalizedFirst := normalizeThaiName(systemFirstName)
	normalizedLast := normalizeThaiName(systemLastName)

	return strings.Contains(normalizedOCR, normalizedFirst) &&
		strings.Contains(normalizedOCR, normalizedLast)
}

func resolveStatus(record *CriminalBlacklist) (CheckStatus, string, string) {
	if record == nil {
		return StatusPassed, "ไม่พบประวัติอาชญากรรม", "ผ่านการตรวจสอบประวัติอาชญากรรม"
	}
	return StatusFailed, record.Note, "ไม่ผ่านการตรวจสอบประวัติอาชญากรรม"
}
