package criminalcheck

import (
	"math"
	"regexp"
	"sort"
	"strings"
)

func normalizeThaiName(name string) string {
	prefixes := []string{"นาย", "นาง", "น.ส.", "นางสาว", "ด.ช.", "ด.ญ."}
	name = strings.TrimSpace(name)
	for _, p := range prefixes {
		name = strings.TrimPrefix(name, p)
	}

	name = strings.ReplaceAll(name, " ", "")
	name = strings.TrimSpace(name)
	return name
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

func resolveStatus(record *MockCriminalRecord) (CheckStatus, string, string, bool) {
	if record == nil {
		return StatusNotFound, "ไม่พบข้อมูลในระบบ", "ไม่พบข้อมูลเลขบัตรประชาชน กรุณาติดต่อเจ้าหน้าที่", false
	}
	switch record.Status {
	case StatusPassed:
		return StatusPassed, record.Note, "ผ่านการตรวจสอบประวัติอาชญากรรม", true
	case StatusFailed:
		return StatusFailed, record.Note, "ไม่ผ่านการตรวจสอบประวัติอาชญากรรม", false
	case StatusPending:
		return StatusPending, record.Note, "อยู่ระหว่างการตรวจสอบประวัติ กรุณารอผล", false
	default:
		return StatusNotFound, record.Note, "ไม่พบข้อมูล", false
	}
}

func extractNationalID(text string) string {

	cleaned := strings.ReplaceAll(text, "-", "")
	cleaned = strings.ReplaceAll(cleaned, " ", "")
	cleaned = strings.ReplaceAll(cleaned, "\n", "")
	cleaned = strings.ReplaceAll(cleaned, "\t", "")

	matches := nationalIDRegex.FindAllString(cleaned, -1)
	if len(matches) > 0 {
		return matches[0]
	}

	digitsOnly := regexp.MustCompile(`[0-9]`).FindAllString(text, -1)
	allDigits := strings.Join(digitsOnly, "")

	for i := 0; i <= len(allDigits)-13; i++ {
		candidate := allDigits[i : i+13]
		if candidate[0] >= '1' && candidate[0] <= '8' {
			return candidate
		}
	}

	return ""
}

func extractThaiName(items []struct {
	Text       string      `json:"text"`
	Confidence float64     `json:"confidence"`
	BBox       [][]float64 `json:"bbox"`
}, idCardY float64) string {

	thaiRegex := regexp.MustCompile(`[\p{Thai}]+`)

	type textItem struct {
		text string
		y    float64
	}

	var thaiItems []textItem
	for _, item := range items {

		if !thaiRegex.MatchString(item.Text) {
			continue
		}

		if len([]rune(item.Text)) < 2 {
			continue
		}
		topY := item.BBox[0][1]
		thaiItems = append(thaiItems, textItem{text: item.Text, y: topY})
	}

	if len(thaiItems) == 0 {
		return ""
	}

	sort.Slice(thaiItems, func(i, j int) bool {
		return thaiItems[i].y < thaiItems[j].y
	})

	var nameParts []string
	var baseY float64 = -1

	for _, item := range thaiItems {
		if item.y <= idCardY {
			continue
		}
		if baseY < 0 {
			baseY = item.y
		}

		if math.Abs(item.y-baseY) <= 30 {
			nameParts = append(nameParts, strings.TrimSpace(item.text))
		}
	}

	return strings.Join(nameParts, " ")
}

func extractNationalIDWithY(items []struct {
	Text       string      `json:"text"`
	Confidence float64     `json:"confidence"`
	BBox       [][]float64 `json:"bbox"`
}) (string, float64) {

	exactRegex := regexp.MustCompile(`^[0-9]{13}$`)
	for _, item := range items {
		cleaned := strings.ReplaceAll(item.Text, "-", "")
		cleaned = strings.ReplaceAll(cleaned, " ", "")
		if exactRegex.MatchString(cleaned) {
			return cleaned, item.BBox[0][1]
		}
	}

	type numItem struct {
		digits string
		topY   float64
		leftX  float64
	}

	var numItems []numItem
	numOnlyRegex := regexp.MustCompile(`^[\d\s\-]+$`)

	for _, item := range items {
		if !numOnlyRegex.MatchString(item.Text) {
			continue
		}
		digits := regexp.MustCompile(`[0-9]`).FindAllString(item.Text, -1)
		if len(digits) == 0 {
			continue
		}
		topY := item.BBox[0][1]
		leftX := item.BBox[0][0]
		numItems = append(numItems, numItem{
			digits: strings.Join(digits, ""),
			topY:   topY,
			leftX:  leftX,
		})
	}

	sort.Slice(numItems, func(i, j int) bool {
		if math.Abs(numItems[i].topY-numItems[j].topY) <= 40 {
			return numItems[i].leftX < numItems[j].leftX
		}
		return numItems[i].topY < numItems[j].topY
	})

	for i := 0; i < len(numItems); i++ {
		combined := numItems[i].digits
		baseY := numItems[i].topY

		for j := i + 1; j < len(numItems); j++ {
			if math.Abs(numItems[j].topY-baseY) > 40 {
				break
			}
			combined += numItems[j].digits

			if len(combined) == 13 {
				return combined, baseY
			}
			if len(combined) > 13 {
				break
			}
		}
	}

	return "", 0
}
