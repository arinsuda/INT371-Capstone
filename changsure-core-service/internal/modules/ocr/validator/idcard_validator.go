package validator

import (
	"errors"
	"regexp"
	"strings"
	"unicode"
)

var (
	ErrEmptyText       = errors.New("empty text")
	ErrInvalidLength   = errors.New("invalid length: must be 13 digits")
	ErrNonDigit        = errors.New("contains non-digit characters")
	ErrInvalidChecksum = errors.New("invalid checksum")
	ErrNoValidID       = errors.New("no valid 13-digit ID found")
)

const (
	idLength       = 13
	checksumLength = 12
)

type IDCardValidator struct {
	digitPattern      *regexp.Regexp
	multiSpacePattern *regexp.Regexp
	thaiIDPatterns    []*regexp.Regexp
}

func NewIDCardValidator() *IDCardValidator {
	return &IDCardValidator{
		digitPattern:      regexp.MustCompile(`\d{13}`),
		multiSpacePattern: regexp.MustCompile(`\s+`),
		thaiIDPatterns: []*regexp.Regexp{
			regexp.MustCompile(`(\d)\s*(\d{4})\s*(\d{5})\s*(\d{2})\s*(\d)`),
			regexp.MustCompile(`(\d)-(\d{4})-(\d{5})-(\d{2})-(\d)`),
			regexp.MustCompile(`(\d{10})\s*(\d{3})`),
			regexp.MustCompile(`(\d)\s*(\d{12})`),
		},
	}
}

var (
	noiseChars = []string{
		":", ";", ".", ",", "!", "?",
		"(", ")", "[", "]", "{", "}",
		"<", ">", "/", "\\", "|", "_", "-",
		"'", "\"", "`", "~", "@", "#", "$", "%", "^", "&", "*", "+", "=",
	}

	ocrReplacements = map[rune]rune{
		'O': '0', 'o': '0', 'Q': '0', 'D': '0',
		'I': '1', 'l': '1', '|': '1', 'i': '1', '!': '1',
		'Z': '2', 'z': '2',
		'A': '4',
		'S': '5', 's': '5',
		'G': '6', 'b': '6',
		'T': '7',
		'B': '8',
		'g': '9', 'q': '9',
		'๐': '0', '๑': '1', '๒': '2', '๓': '3', '๔': '4',
		'๕': '5', '๖': '6', '๗': '7', '๘': '8', '๙': '9',
		'０': '0', '１': '1', '２': '2', '３': '3', '４': '4',
		'５': '5', '６': '6', '７': '7', '８': '8', '９': '9',
	}

	firstDigitSubstitutes = map[rune][]rune{
		'1': {'7', '4'},
		'4': {'1', '7'},
		'0': {'8', '3'},
		'7': {'1', '4'},
		'8': {'0', '3', '1'},
		'3': {'8', '5'},
		'5': {'3', '8'},
		'6': {'8'},
		'9': {'8'},
	}

	firstDigitFrequency = map[rune]int{
		'1': 100, '3': 90, '5': 80, '7': 70, '8': 60,
		'2': 50, '4': 40, '6': 30, '0': 10, '9': 10,
	}
)

func (v *IDCardValidator) cleanOCRNoise(text string) string {
	cleaned := text
	for _, noise := range noiseChars {
		cleaned = strings.ReplaceAll(cleaned, noise, " ")
	}
	cleaned = v.multiSpacePattern.ReplaceAllString(cleaned, " ")
	return strings.TrimSpace(cleaned)
}

func (v *IDCardValidator) normalizeOCRText(text string) string {
	var result strings.Builder
	result.Grow(len(text))
	for _, r := range text {
		if replacement, exists := ocrReplacements[r]; exists {
			result.WriteRune(replacement)
		} else {
			result.WriteRune(r)
		}
	}
	return result.String()
}

func (v *IDCardValidator) extractDigitsOnly(text string) string {
	var digits strings.Builder
	for _, r := range text {
		if unicode.IsDigit(r) && r >= '0' && r <= '9' {
			digits.WriteRune(r)
		}
	}
	return digits.String()
}

func (v *IDCardValidator) findThaiIDPattern(text string) string {
	for _, pattern := range v.thaiIDPatterns {
		matches := pattern.FindStringSubmatch(text)
		if len(matches) > 0 {
			var id strings.Builder
			for i := 1; i < len(matches); i++ {
				id.WriteString(matches[i])
			}
			if id.Len() == idLength {
				candidate := id.String()
				if v.ValidateChecksum(candidate) == nil {
					return candidate
				}
			}
		}
	}
	return ""
}

type candidateScore struct {
	id    string
	score int
}

func (v *IDCardValidator) findIDWithSpaces(text string) string {
	cleaned := regexp.MustCompile(`[^\d\s]`).ReplaceAllString(text, "")
	cleaned = v.multiSpacePattern.ReplaceAllString(cleaned, " ")
	cleaned = strings.TrimSpace(cleaned)

	parts := strings.Fields(cleaned)
	if len(parts) == 0 {
		return ""
	}

	var candidates []candidateScore

	patterns := [][]int{
		{1, 4, 5, 2, 1},
		{1, 4, 5, 3},
		{5, 5, 3},
		{5, 5, 2, 1},
		{2, 4, 5, 2},
		{1, 5, 5, 2},
	}

	for _, pattern := range patterns {
		if len(parts) != len(pattern) {
			continue
		}

		var id strings.Builder
		valid := true

		for i, expectedLen := range pattern {
			if len(parts[i]) != expectedLen {
				valid = false
				break
			}
			id.WriteString(parts[i])
		}

		if !valid || id.Len() != idLength {
			continue
		}

		candidate := id.String()

		if v.ValidateChecksum(candidate) == nil {
			firstDigit := rune(candidate[0])
			score := firstDigitFrequency[firstDigit] + 20
			candidates = append(candidates, candidateScore{candidate, score})
		}

		for lastDigit := '0'; lastDigit <= '9'; lastDigit++ {
			fixed := candidate[:12] + string(lastDigit)
			if v.ValidateChecksum(fixed) == nil {
				firstDigit := rune(fixed[0])
				score := firstDigitFrequency[firstDigit] + 15
				candidates = append(candidates, candidateScore{fixed, score})
			}
		}

		firstDigit := rune(candidate[0])
		if substitutes, exists := firstDigitSubstitutes[firstDigit]; exists {
			for _, sub := range substitutes {
				fixed := string(sub) + candidate[1:]
				if v.ValidateChecksum(fixed) == nil {
					score := firstDigitFrequency[sub] + 10
					candidates = append(candidates, candidateScore{fixed, score})
				}
			}
		}
	}

	if len(parts) == 3 && len(parts[0]) == 5 && len(parts[1]) == 5 && len(parts[2]) == 3 {
		firstPart := parts[0]

		for splitPos := 1; splitPos <= 2; splitPos++ {
			part1 := firstPart[:splitPos]
			part2 := firstPart[splitPos:]

			baseCandidate := part1 + part2 + parts[1] + parts[2]

			if len(baseCandidate) == idLength {

				if v.ValidateChecksum(baseCandidate) == nil {
					firstDigit := rune(baseCandidate[0])
					score := firstDigitFrequency[firstDigit] + 25
					candidates = append(candidates, candidateScore{baseCandidate, score})
				}

				for lastDigit := '0'; lastDigit <= '9'; lastDigit++ {
					fixed := baseCandidate[:12] + string(lastDigit)
					if v.ValidateChecksum(fixed) == nil {
						firstDigit := rune(fixed[0])
						score := firstDigitFrequency[firstDigit] + 20
						candidates = append(candidates, candidateScore{fixed, score})
					}
				}
			}
		}
	}

	if len(parts) == 4 && len(parts[0]) == 5 && len(parts[1]) == 5 && len(parts[2]) == 2 && len(parts[3]) == 1 {
		firstPart := parts[0]

		for splitPos := 1; splitPos < len(firstPart); splitPos++ {
			part1 := firstPart[:splitPos]
			part2 := firstPart[splitPos:]

			if (len(part1) == 1 && len(part2) == 4) || (len(part1) == 2 && len(part2) == 3) {
				baseCandidate := part1 + part2 + parts[1] + parts[2] + parts[3]

				if len(baseCandidate) == idLength {

					if v.ValidateChecksum(baseCandidate) == nil {
						firstDigit := rune(baseCandidate[0])
						score := firstDigitFrequency[firstDigit] + 25
						candidates = append(candidates, candidateScore{baseCandidate, score})
					}

					for lastDigit := '0'; lastDigit <= '9'; lastDigit++ {
						fixed := baseCandidate[:12] + string(lastDigit)
						if v.ValidateChecksum(fixed) == nil {
							firstDigit := rune(fixed[0])
							score := firstDigitFrequency[firstDigit] + 20
							candidates = append(candidates, candidateScore{fixed, score})
						}
					}
				}
			}
		}
	}

	if len(candidates) > 0 {
		best := candidates[0]
		for _, c := range candidates[1:] {
			if c.score > best.score {
				best = c
			}
		}
		return best.id
	}

	return ""
}

func (v *IDCardValidator) trySlidingWindow(digits string) (string, bool) {
	if len(digits) < idLength {
		return "", false
	}
	for i := 0; i+idLength <= len(digits); i++ {
		candidate := digits[i : i+idLength]
		if v.ValidateChecksum(candidate) == nil {
			return candidate, true
		}
	}
	return "", false
}

func (v *IDCardValidator) tryFirstDigitSubstitutionWithScoring(digits string) (string, bool) {
	if len(digits) < idLength {
		return "", false
	}

	var candidates []candidateScore

	for i := 0; i+idLength <= len(digits); i++ {
		candidate := digits[i : i+idLength]
		firstDigit := rune(candidate[0])

		if v.ValidateChecksum(candidate) == nil {
			score := firstDigitFrequency[firstDigit]
			candidates = append(candidates, candidateScore{candidate, score})
		}

		if substitutes, exists := firstDigitSubstitutes[firstDigit]; exists {
			for _, sub := range substitutes {
				modified := string(sub) + candidate[1:]
				if v.ValidateChecksum(modified) == nil {
					score := firstDigitFrequency[sub]
					candidates = append(candidates, candidateScore{modified, score})
				}
			}
		}
	}

	if len(candidates) > 0 {
		best := candidates[0]
		for _, c := range candidates[1:] {
			if c.score > best.score {
				best = c
			}
		}
		return best.id, true
	}

	return "", false
}

func (v *IDCardValidator) tryAllFirstDigitCombinations(digits string) (string, bool) {
	if len(digits) < idLength {
		return "", false
	}

	commonFirstDigits := []rune{'1', '3', '5', '7', '8', '2', '4', '6'}

	for i := 0; i+idLength <= len(digits); i++ {
		candidate := digits[i : i+idLength]
		for _, digit := range commonFirstDigits {
			modified := string(digit) + candidate[1:]
			if v.ValidateChecksum(modified) == nil {
				return modified, true
			}
		}
	}

	return "", false
}

func (v *IDCardValidator) ExtractIDNumber(text string) (string, error) {
	if text == "" {
		return "", ErrEmptyText
	}

	cleaned := v.cleanOCRNoise(text)

	if id := v.digitPattern.FindString(cleaned); id != "" {
		if v.ValidateChecksum(id) == nil {
			return id, nil
		}
	}

	normalized := v.normalizeOCRText(cleaned)

	if id := v.findIDWithSpaces(normalized); id != "" {
		return id, nil
	}

	if id := v.digitPattern.FindString(normalized); id != "" {
		if v.ValidateChecksum(id) == nil {
			return id, nil
		}
	}

	if id := v.findThaiIDPattern(normalized); id != "" {
		return id, nil
	}

	digitsOnly := v.extractDigitsOnly(normalized)

	if id, found := v.trySlidingWindow(digitsOnly); found {
		return id, nil
	}

	if id, found := v.tryFirstDigitSubstitutionWithScoring(digitsOnly); found {
		return id, nil
	}

	if id, found := v.tryAllFirstDigitCombinations(digitsOnly); found {
		return id, nil
	}

	return "", ErrNoValidID
}

func (v *IDCardValidator) ValidateChecksum(id string) error {
	if len(id) != idLength {
		return ErrInvalidLength
	}

	for _, r := range id {
		if r < '0' || r > '9' {
			return ErrNonDigit
		}
	}

	sum := 0
	for i := 0; i < checksumLength; i++ {
		digit := int(id[i] - '0')
		sum += digit * (idLength - i)
	}

	expectedChecksum := (11 - (sum % 11)) % 10
	actualChecksum := int(id[checksumLength] - '0')

	if expectedChecksum != actualChecksum {
		return ErrInvalidChecksum
	}

	return nil
}

func (v *IDCardValidator) Validate(id string) error {
	return v.ValidateChecksum(id)
}

func (v *IDCardValidator) DebugExtractIDNumber(text string) (string, []string, error) {
	var logs []string

	if text == "" {
		return "", logs, ErrEmptyText
	}

	logs = append(logs, "Input: "+text)

	cleaned := v.cleanOCRNoise(text)
	logs = append(logs, "Cleaned: "+cleaned)

	if id := v.digitPattern.FindString(cleaned); id != "" {
		logs = append(logs, "Found 13 digits: "+id)
		if v.ValidateChecksum(id) == nil {
			logs = append(logs, "✓ Checksum valid")
			return id, logs, nil
		}
		logs = append(logs, "✗ Checksum invalid")
	}

	normalized := v.normalizeOCRText(cleaned)
	logs = append(logs, "Normalized: "+normalized)

	logs = append(logs, "Trying findIDWithSpaces...")
	if id := v.findIDWithSpaces(normalized); id != "" {
		logs = append(logs, "Found via findIDWithSpaces: "+id)
		return id, logs, nil
	}
	logs = append(logs, "✗ findIDWithSpaces returned empty")

	digitsOnly := v.extractDigitsOnly(normalized)
	logs = append(logs, "Digits only: "+digitsOnly)

	if id, found := v.trySlidingWindow(digitsOnly); found {
		logs = append(logs, "Found via sliding window: "+id)
		return id, logs, nil
	}

	if id, found := v.tryFirstDigitSubstitutionWithScoring(digitsOnly); found {
		logs = append(logs, "Found via first digit substitution: "+id)
		return id, logs, nil
	}

	return "", logs, ErrNoValidID
}
