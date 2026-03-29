package database

import (
	"strings"
)

func normalizeTH(s string) string {
	return strings.TrimSpace(s)
}

func stripThaiPrefix(s string, prefixes ...string) string {
	out := normalizeTH(s)
	for _, p := range prefixes {
		if strings.HasPrefix(out, p) {
			out = strings.TrimSpace(strings.TrimPrefix(out, p))
		}
	}
	return out
}

func uniqueStrings(in []string) []string {
	seen := make(map[string]struct{}, len(in))
	out := make([]string, 0, len(in))
	for _, s := range in {
		s = normalizeTH(s)
		if s == "" {
			continue
		}
		if _, ok := seen[s]; ok {
			continue
		}
		seen[s] = struct{}{}
		out = append(out, s)
	}
	return out
}
