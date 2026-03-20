package auth

import (
	"changsure-core-service/internal/jwtutil"
)

const (
	RoleCustomer   = jwtutil.RoleCustomer
	RoleTechnician = jwtutil.RoleTechnician
	RoleAdmin      = jwtutil.RoleAdmin

	TokenTypeAccess  = jwtutil.TokenTypeAccess
	TokenTypeRefresh = jwtutil.TokenTypeRefresh
)

type TokenConfig = jwtutil.Config

type JWTClaims = jwtutil.IssueInput

func IssueTokenPair(cfg TokenConfig, claims JWTClaims) (string, string, error) {
	return jwtutil.IssueTokenPair(cfg, claims)
}

func IssueAccessToken(cfg TokenConfig, claims JWTClaims) (string, error) {
	return jwtutil.IssueAccessToken(cfg, claims)
}

func AccessTTLSeconds(cfg TokenConfig) int64 {
	return cfg.AccessTTLSeconds()
}
