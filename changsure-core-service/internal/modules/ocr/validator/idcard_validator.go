package validator

import (
	"errors"
	"regexp"
)

// IDCardValidator ตรวจและดึงเลขบัตรประชาชนไทย
type IDCardValidator struct{}

func NewIDCardValidator() *IDCardValidator {
	return &IDCardValidator{}
}

// ExtractIDNumber ดึง 13 หลักแรกที่ดูเหมือนเลขบัตรจากข้อความ
func (v *IDCardValidator) ExtractIDNumber(text string) (string, error) {
	re := regexp.MustCompile(`\d{13}`)
	id := re.FindString(text)
	if id == "" {
		return "", errors.New("no 13-digit number found")
	}
	// ตรวจ checksum ให้ด้วย (optional)
	if err := v.ValidateChecksum(id); err != nil {
		return "", err
	}
	return id, nil
}

// ValidateChecksum ตรวจสอบเลขบัตรประชาชนไทย 13 หลัก
func (v *IDCardValidator) ValidateChecksum(id string) error {
	if len(id) != 13 {
		return errors.New("invalid length")
	}
	sum := 0
	for i := 0; i < 12; i++ {
		d := int(id[i] - '0')
		sum += d * (13 - i)
	}
	check := (11 - (sum % 11)) % 10
	if check != int(id[12]-'0') {
		return errors.New("invalid checksum")
	}
	return nil
}
