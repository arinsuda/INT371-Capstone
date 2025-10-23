package registry

import (
	"changsure-core-service/internal/modules/customers"
	"changsure-core-service/internal/modules/provinces"
	"changsure-core-service/internal/modules/reservation_statuses"
	"changsure-core-service/internal/modules/reservations"
	"changsure-core-service/internal/modules/service_categories"
	"changsure-core-service/internal/modules/services"
	"changsure-core-service/internal/modules/technicians"

	ocrmod "changsure-core-service/internal/modules/ocr"
	ocrhandler "changsure-core-service/internal/modules/ocr/handler"

	"context"
	"fmt"

	"gorm.io/gorm"
)

type ContainerOption func(*Container) error

func WithOCROptions(setup func() (*ocrmod.OCRModule, error)) ContainerOption {
	return func(c *Container) error {
		mod, err := setup()
		if err != nil {
			return fmt.Errorf("init OCR module: %w", err)
		}
		c.ocrModule = mod
		c.OCRHandler = mod.Handler
		return nil
	}
}

type Container struct {
	DB *gorm.DB

	CustomerRepo customers.Repository

	CustomerService customers.Service

	CustomerHandler *customers.Handler
	OCRHandler      *ocrhandler.OCRHandler

	ocrModule *ocrmod.OCRModule
}

func NewContainer(db *gorm.DB, opts ...ContainerOption) (*Container, error) {
	if db == nil {
		return nil, fmt.Errorf("db is nil")
	}

	c := &Container{DB: db}

	c.CustomerRepo = customers.NewRepository(db)

	c.CustomerService = customers.NewService(c.CustomerRepo)

	c.CustomerHandler = customers.NewHandler(c.CustomerService)

	defaultOCR := func() (*ocrmod.OCRModule, error) {
		return ocrmod.NewOCRModule()
	}

	if err := WithOCROptions(defaultOCR)(c); err != nil {
		return nil, err
	}

	for _, opt := range opts {
		if err := opt(c); err != nil {
			return nil, err
		}
	}

	return c, nil
}

func (c *Container) Close(ctx context.Context) error {
	var firstErr error

	if c.ocrModule != nil {
		if err := c.ocrModule.Close(); err != nil && firstErr == nil {
			firstErr = fmt.Errorf("close OCR module: %w", err)
		}
	}

	return firstErr
}

func AllModels() []interface{} {
	var all []interface{}
	all = append(all, provinces.Models()...)
	all = append(all, reservation_statuses.Models()...)
	all = append(all, service_categories.Models()...)
	all = append(all, services.Models()...)
	all = append(all, technicians.Models()...)
	all = append(all, customers.Models()...)
	all = append(all, reservations.Models()...)
	return all
}
