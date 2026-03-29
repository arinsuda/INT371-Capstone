package addressshared

import "strings"

func normalizeStr(s *string) *string {
	if s == nil {
		return nil
	}
	v := strings.TrimSpace(*s)
	if v == "" {
		return nil
	}
	return &v
}

func normalizeMoo(m *string) *string {
	m = normalizeStr(m)
	if m == nil {
		return nil
	}

	v := *m
	v = strings.TrimPrefix(v, "หมู่")
	v = strings.TrimPrefix(v, "ม.")
	v = strings.TrimPrefix(v, "ม")
	v = strings.TrimSpace(v)

	if v == "" {
		return nil
	}
	return &v
}

func NormalizeAddressFields(a *AddressFields) {
	a.Label = normalizeStr(a.Label)
	a.PhoneNumber = normalizeStr(a.PhoneNumber)
	a.AddressLine = normalizeStr(a.AddressLine)
	a.HouseNumber = normalizeStr(a.HouseNumber)
	a.Village = normalizeStr(a.Village)
	a.Soi = normalizeStr(a.Soi)
	a.Road = normalizeStr(a.Road)
	a.Moo = normalizeMoo(a.Moo)
}
