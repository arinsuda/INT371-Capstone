package payment

import (
	"changsure-core-service/internal/config"
	"errors"
	"time"
)

type Config struct {
	Omise config.OmiseConfig
}

func (c *Config) Validate() error {
	if c.Omise.PublicKey == "" {
		return errors.New("omise public key is required")
	}
	if c.Omise.SecretKey == "" {
		return errors.New("omise secret key is required")
	}
	if c.Omise.Currency == "" {
		c.Omise.Currency = "thb"
	}
	if c.Omise.Timeout == 0 {
		c.Omise.Timeout = 30 * time.Second
	}
	if c.Omise.QRExpiryMinutes == 0 {
		c.Omise.QRExpiryMinutes = 15
	}
	return nil
}
