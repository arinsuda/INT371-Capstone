package utils

import "time"


func NormalizeDate(t time.Time) time.Time {
	return time.Date(
		t.Year(),
		t.Month(),
		t.Day(),
		0, 0, 0, 0,
		time.UTC,
	)
}


func ParseDateString(dateStr string) (time.Time, error) {
	t, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return time.Time{}, err
	}
	return NormalizeDate(t), nil
}
