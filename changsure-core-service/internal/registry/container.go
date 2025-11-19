package registry

import (
	"context"
	"fmt"

	"gorm.io/gorm"

	"changsure-core-service/internal/modules/badge"
	customeraddresses "changsure-core-service/internal/modules/customer_addresses"
	"changsure-core-service/internal/modules/customers"
	ocrmod "changsure-core-service/internal/modules/ocr"
	ocrhandler "changsure-core-service/internal/modules/ocr/handler"
	"changsure-core-service/internal/modules/provinces"
	"changsure-core-service/internal/modules/service_categories"
	"changsure-core-service/internal/modules/services"
	"changsure-core-service/internal/modules/technician_addresses"
	"changsure-core-service/internal/modules/technician_badges"
	"changsure-core-service/internal/modules/technician_services"
	techworks "changsure-core-service/internal/modules/technician_works"
	"changsure-core-service/internal/modules/technicians"

	"changsure-core-service/internal/config"
	"changsure-core-service/pkg/storage"
)

type ContainerOption func(*Container) error

func WithOCRModule(setup func() (*ocrmod.OCRModule, error)) ContainerOption {
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
	DB      *gorm.DB
	Storage *storage.MinioStorage

	CustomerRepo    customers.Repository
	CustomerService customers.Service
	CustomerHandler *customers.Handler

	CustomerAddressRepo    customeraddresses.Repository
	CustomerAddressService customeraddresses.Service
	CustomerAddressHandler *customeraddresses.Handler

	ProvinceRepo    provinces.Repository
	ProvinceService provinces.Service
	ProvinceHandler *provinces.Handler

	TechnicianRepo    technicians.Repository
	TechnicianService technicians.Service
	TechnicianHandler *technicians.Handler

	TechnicianServiceRepo    technician_services.Repository
	TechnicianServiceService technician_services.Service
	TechnicianServiceHandler *technician_services.Handler

	TechnicianAddressRepo technician_addresses.Repository

	ServiceCategoryRepo    service_categories.Repository
	ServiceCategoryService service_categories.Service
	ServiceCategoryHandler *service_categories.Handler

	ServiceRepo    services.Repository
	ServiceService services.ServiceSvc
	ServiceHandler *services.Handler

	BadgeRepo    badge.Repository
	BadgeService badge.Service
	BadgeHandler *badge.RouteBundle

	TechnicianBadgeRepo    technician_badges.Repository
	TechnicianBadgeService technician_badges.Service
	TechnicianBadgeHandler *technician_badges.Handler

	TechnicianWorkRepo    techworks.Repository
	TechnicianWorkService techworks.Service
	TechnicianWorkHandler *techworks.Handler

	OCRHandler *ocrhandler.OCRHandler

	ocrModule *ocrmod.OCRModule
}

func NewContainer(db *gorm.DB, cfg *config.Config, opts ...ContainerOption) (*Container, error) {
	if db == nil {
		return nil, fmt.Errorf("database connection is required")
	}
	if cfg == nil {
		return nil, fmt.Errorf("configuration is required")
	}

	c := &Container{DB: db}

	if err := c.initStorage(cfg); err != nil {
		return nil, err
	}

	c.initCustomerModule()
	c.initProvinceModule()
	c.initCustomerAddressModule()
	c.initTechnicianModule()
	c.initTechnicianServiceModule()
	c.initServiceCategoryModule(cfg)
	c.initServiceModule()
	c.initBadgeModule()
	c.initTechnicianBadgeModule()
	c.initTechnicianWorkModule()

	if err := c.initOCRModule(); err != nil {
		return nil, err
	}

	for _, opt := range opts {
		if err := opt(c); err != nil {
			return nil, fmt.Errorf("apply container option: %w", err)
		}
	}

	return c, nil
}

func (c *Container) initStorage(cfg *config.Config) error {
	store, err := storage.NewMinioFromConfig(cfg.Minio)
	if err != nil {
		return fmt.Errorf("init minio storage: %w", err)
	}
	c.Storage = store
	return nil
}

func (c *Container) initCustomerModule() {
	c.CustomerRepo = customers.NewRepository(c.DB)
	c.CustomerService = customers.NewService(c.CustomerRepo)
	c.CustomerHandler = customers.NewHandler(c.CustomerService)
}

func (c *Container) initProvinceModule() {
	c.ProvinceRepo = provinces.NewRepository(c.DB)
	c.ProvinceService = provinces.NewService(c.ProvinceRepo)
	c.ProvinceHandler = provinces.NewHandler(c.ProvinceService)
}

func (c *Container) initCustomerAddressModule() {
	c.CustomerAddressRepo = customeraddresses.NewRepository(c.DB)
	c.CustomerAddressService = customeraddresses.NewService(
		c.CustomerAddressRepo,
		c.CustomerRepo,
	)
	c.CustomerAddressHandler = customeraddresses.NewHandler(c.CustomerAddressService)
}

func (c *Container) initTechnicianModule() {
	c.TechnicianRepo = technicians.NewRepository(c.DB)
	c.TechnicianAddressRepo = technician_addresses.NewRepository(c.DB)
	c.TechnicianService = technicians.NewService(
		c.DB,
		c.TechnicianRepo,
		c.TechnicianAddressRepo,
	)
	c.TechnicianHandler = technicians.NewHandler(c.TechnicianService)
}

func (c *Container) initTechnicianServiceModule() {
	c.TechnicianServiceRepo = technician_services.NewRepository(c.DB)
	c.TechnicianServiceService = technician_services.NewService(c.TechnicianServiceRepo)
	c.TechnicianServiceHandler = technician_services.NewHandler(c.TechnicianServiceService)
}

func (c *Container) initServiceCategoryModule(cfg *config.Config) {
	c.ServiceCategoryRepo = service_categories.NewRepository(c.DB)
	c.ServiceCategoryService = service_categories.NewService(c.ServiceCategoryRepo)
	c.ServiceCategoryHandler = service_categories.NewHandler(
		c.ServiceCategoryService,
		c.Storage,
		cfg,
	)
}

func (c *Container) initServiceModule() {
	c.ServiceRepo = services.NewRepository(c.DB)
	c.ServiceService = services.NewService(c.ServiceRepo)
	c.ServiceHandler = services.NewHandler(c.ServiceService)
}

func (c *Container) initOCRModule() error {
	defaultOCR := func() (*ocrmod.OCRModule, error) {
		return ocrmod.NewOCRModule()
	}
	return WithOCRModule(defaultOCR)(c)
}

func (c *Container) initBadgeModule() {
	c.BadgeRepo = badge.NewRepository(c.DB)
	c.BadgeService = badge.NewService(c.BadgeRepo)
	c.BadgeHandler = badge.NewRouteBundle(c.DB, c.Storage)
}

func (c *Container) initTechnicianBadgeModule() {
	c.TechnicianBadgeRepo = technician_badges.NewRepository(c.DB)

	c.TechnicianBadgeService = technician_badges.NewService(
		c.TechnicianBadgeRepo,
		c.TechnicianRepo,
	)

	c.TechnicianBadgeHandler = technician_badges.NewHandler(c.TechnicianBadgeService)
}

func (c *Container) initTechnicianWorkModule() {
	c.TechnicianWorkRepo = techworks.NewRepository(c.DB)
	c.TechnicianWorkService = techworks.NewService(c.TechnicianWorkRepo)
	c.TechnicianWorkHandler = techworks.NewHandler(c.TechnicianWorkService)
}

func (c *Container) Close(ctx context.Context) error {
	if c.ocrModule != nil {
		if err := c.ocrModule.Close(); err != nil {
			return fmt.Errorf("close OCR module: %w", err)
		}
	}
	return nil
}

func AllModels() []interface{} {
	models := make([]interface{}, 0)

	models = append(models, provinces.Models()...)
	models = append(models, service_categories.Models()...)
	models = append(models, services.Models()...)
	models = append(models, customers.Models()...)
	models = append(models, technicians.Models()...)

	models = append(models, customeraddresses.Models()...)
	models = append(models, technician_addresses.Models()...)
	models = append(models, technician_services.Models()...)

	models = append(models, badge.Models()...)
	models = append(models, technician_badges.Models()...)
	models = append(models, techworks.Models()...)

	return models
}
