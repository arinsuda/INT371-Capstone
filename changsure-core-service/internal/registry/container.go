package registry

import (
	customeraddresses "changsure-core-service/internal/modules/customer_addresses"
	"changsure-core-service/internal/modules/customers"
	"changsure-core-service/internal/modules/provinces"

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

	// Repositories
	CustomerRepo        customers.Repository
	CustomerAddressRepo customeraddresses.Repository
	ProvinceRepo        provinces.Repository

	// Services
	CustomerService        customers.Service
	CustomerAddressService customeraddresses.Service
	ProvinceService        provinces.Service

	// Handlers
	CustomerHandler        *customers.Handler
	CustomerAddressHandler *customeraddresses.Handler
	ProvinceHandler        *provinces.Handler
	OCRHandler             *ocrhandler.OCRHandler

	ocrModule *ocrmod.OCRModule
}

func NewContainer(db *gorm.DB, opts ...ContainerOption) (*Container, error) {
	if db == nil {
		return nil, fmt.Errorf("db is nil")
	}
	c := &Container{DB: db}

	// ---------- Customers ----------
	c.CustomerRepo = customers.NewRepository(db)
	c.CustomerService = customers.NewService(c.CustomerRepo)
	c.CustomerHandler = customers.NewHandler(c.CustomerService)

	// ---------- Provinces ----------
	c.ProvinceRepo = provinces.NewRepository(db)
	c.ProvinceService = provinces.NewService(c.ProvinceRepo)
	c.ProvinceHandler = provinces.NewHandler(c.ProvinceService)

	// ---------- Customer Addresses ----------
	c.CustomerAddressRepo = customeraddresses.NewRepository(db)
	c.CustomerAddressService = customeraddresses.NewService(c.CustomerAddressRepo, c.CustomerRepo)
	c.CustomerAddressHandler = customeraddresses.NewHandler(c.CustomerAddressService)

	// ---------- OCR (optional) ----------
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
	// ควรสร้างตารางที่ถูกอ้างอิงก่อน (provinces) แล้วค่อย customers -> customer_addresses
	all = append(all, provinces.Models()...)
	all = append(all, customers.Models()...)
	all = append(all, customeraddresses.Models()...)
	return all
}