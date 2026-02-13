package utils

import "time"

// NormalizeDate converts any time → UTC 00:00:00
func NormalizeDate(t time.Time) time.Time {
	return time.Date(
		t.Year(),
		t.Month(),
		t.Day(),
		0, 0, 0, 0,
		time.UTC,
	)
}

// ParseDateString parses YYYY-MM-DD safely
func ParseDateString(dateStr string) (time.Time, error) {
	t, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return time.Time{}, err
	}
	return NormalizeDate(t), nil
}
