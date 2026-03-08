package criminalcheck

import (
	"math"
	"regexp"
	"sort"
	"strings"

	"changsure-core-service/internal/modules/ocr/infra"
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

// extractNationalIDWithY tries to find a 13-digit national ID from OCR items.
// Returns the ID and the top-left Y coordinate of the item it was found in.
func extractNationalIDWithY(items []infra.OCRItem) (string, float64) {
	exactRegex := regexp.MustCompile(`^[0-9]{13}$`)

	// Pass 1: look for an item whose cleaned text is exactly 13 digits
	for _, item := range items {
		cleaned := strings.ReplaceAll(item.Text, "-", "")
		cleaned = strings.ReplaceAll(cleaned, " ", "")
		if exactRegex.MatchString(cleaned) {
			return cleaned, item.BBox.TopLeft[1]
		}
	}

	// Pass 2: collect digit-only items and try to assemble 13 digits
	// by merging items on the same horizontal line (within 40px Y tolerance)
	type numItem struct {
		digits string
		topY   float64
		leftX  float64
	}

	numOnlyRegex := regexp.MustCompile(`^[\d\s\-]+$`)
	digitRegex := regexp.MustCompile(`[0-9]`)

	var numItems []numItem
	for _, item := range items {
		if !numOnlyRegex.MatchString(item.Text) {
			continue
		}
		digits := digitRegex.FindAllString(item.Text, -1)
		if len(digits) == 0 {
			continue
		}
		numItems = append(numItems, numItem{
			digits: strings.Join(digits, ""),
			topY:   item.BBox.TopLeft[1],
			leftX:  item.BBox.TopLeft[0],
		})
	}

	// Sort by Y then X so left-to-right order is preserved on same line
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

// extractThaiName finds the Thai name line that appears just below the ID card
// number row (identified by idCardY). Items within 30px Y of each other on
// that first Thai line are joined as name parts.
func extractThaiName(items []infra.OCRItem, idCardY float64) string {
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
		thaiItems = append(thaiItems, textItem{
			text: item.Text,
			y:    item.BBox.TopLeft[1],
		})
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
		// Skip items above or at the ID number row
		if item.y <= idCardY {
			continue
		}
		if baseY < 0 {
			baseY = item.y
		}
		// Only collect items on the same line as the first Thai text found
		if math.Abs(item.y-baseY) <= 30 {
			nameParts = append(nameParts, strings.TrimSpace(item.text))
		}
	}

	return strings.Join(nameParts, " ")
}