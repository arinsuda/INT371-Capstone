package registry

import (
	"fmt"

	"gorm.io/gorm"

	"changsure-core-service/internal/modules/auth"
	"changsure-core-service/internal/modules/badge"
	customer "changsure-core-service/internal/modules/customer"
	customeraddresses "changsure-core-service/internal/modules/customer_address"
	ocrhandler "changsure-core-service/internal/modules/ocr/handler"
	ocrinfra "changsure-core-service/internal/modules/ocr/infra"
	ocrservice "changsure-core-service/internal/modules/ocr/service"
	"changsure-core-service/internal/modules/province"
	"changsure-core-service/internal/modules/service"
	"changsure-core-service/internal/modules/service_category"
	"changsure-core-service/internal/modules/technician"
	"changsure-core-service/internal/modules/technician_address"
	"changsure-core-service/internal/modules/technician_badge"
	technicianmatching "changsure-core-service/internal/modules/technician_matching"
	techworks "changsure-core-service/internal/modules/technician_post"
	"changsure-core-service/internal/modules/technician_service"
	"changsure-core-service/internal/modules/technician_service_area"

	"changsure-core-service/internal/config"
	"changsure-core-service/pkg/storage"
)

type ContainerOption func(*Container) error

type Container struct {
	DB      *gorm.DB
	Storage *storage.MinioStorage

	AuthRepo    auth.RefreshTokenRepository
	AuthService auth.Service
	AuthHandler *auth.Handler

	CustomerRepo    customer.Repository
	CustomerService customer.Service
	CustomerHandler *customer.Handler

	CustomerAddressRepo    customeraddresses.Repository
	CustomerAddressService customeraddresses.Service
	CustomerAddressHandler *customeraddresses.Handler

	TechnicianMatchingRepo    technicianmatching.Repository
	TechnicianMatchingService technicianmatching.Service
	TechnicianMatchingHandler *technicianmatching.Handler

	ProvinceRepo    province.Repository
	ProvinceService province.Service
	ProvinceHandler *province.Handler

	TechnicianRepo    technician.Repository
	TechnicianService technician.Service
	TechnicianHandler *technician.Handler

	TechnicianServiceRepo    technicianservice.Repository
	TechnicianServiceService technicianservice.Service
	TechnicianServiceHandler *technicianservice.Handler

	TechnicianAddressRepo    technicianaddress.Repository
	TechnicianAddressService technicianaddress.Service
	TechnicianAddressHandler *technicianaddress.Handler

	TechnicianServiceAreaRepo technicianservicearea.Repository

	ServiceCategoryRepo    servicecategory.Repository
	ServiceCategoryService servicecategory.Service
	ServiceCategoryHandler *servicecategory.Handler

	ServiceRepo    service.Repository
	ServiceService service.ServiceSvc
	ServiceHandler *service.Handler

	BadgeRepo    badge.Repository
	BadgeService badge.Service
	BadgeHandler *badge.RouteBundle

	TechnicianBadgeRepo    technicianbadge.Repository
	TechnicianBadgeService technicianbadge.Service
	TechnicianBadgeHandler *technicianbadge.Handler

	TechnicianPostRepo    techworks.Repository
	TechnicianPostService techworks.Service
	TechnicianPostHandler *techworks.Handler

	OCRService ocrservice.OCRService
	OCRHandler *ocrhandler.OCRHandler
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

	c.initTechnicianServiceModule()
	c.initTechnicianModule()

	c.initAuthModule(cfg)
	c.initOCRModule(cfg)

	c.initServiceCategoryModule(cfg)
	c.initServiceModule()
	c.initBadgeModule()
	c.initTechnicianBadgeModule()
	c.initTechnicianWorkModule()
	c.initTechnicianAddressModule()
	c.initCustomerAddressModule()
	c.initTechnicianMatchingModule()

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

	storage.GlobalMinio = store

	return nil
}

func (c *Container) initAuthModule(cfg *config.Config) {
	c.AuthRepo = auth.NewRefreshTokenRepository(c.DB)

	c.AuthService = auth.NewService(
		c.CustomerRepo,
		c.TechnicianRepo,
		c.AuthRepo,
		cfg,
	)

	c.AuthHandler = auth.NewHandler(c.AuthService)
}

func (c *Container) initOCRModule(cfg *config.Config) {
	ocrCfg := cfg.OCR

	client := ocrinfra.NewOCRClient(ocrCfg.BaseURL)
	c.OCRService = ocrservice.NewOCRService(client)
	c.OCRHandler = ocrhandler.NewOCRHandler(c.OCRService)
}

func (c *Container) initCustomerModule() {
	c.CustomerRepo = customer.NewRepository(c.DB)
	c.CustomerService = customer.NewService(c.CustomerRepo)
	c.CustomerHandler = customer.NewHandler(c.CustomerService)
}

func (c *Container) initProvinceModule() {
	c.ProvinceRepo = province.NewRepository(c.DB)
	c.ProvinceService = province.NewService(c.ProvinceRepo)
	c.ProvinceHandler = province.NewHandler(c.ProvinceService)
}

func (c *Container) initCustomerAddressModule() {
	c.CustomerAddressRepo = customeraddresses.NewRepository(c.DB)
	c.CustomerAddressService = customeraddresses.NewService(
		c.CustomerAddressRepo,
		c.TechnicianAddressRepo,
	)
	c.CustomerAddressHandler = customeraddresses.NewHandler(c.CustomerAddressService)
}

func (c *Container) initTechnicianMatchingModule() {
	c.TechnicianMatchingRepo = technicianmatching.NewRepository(c.DB)
	c.TechnicianMatchingService = technicianmatching.NewService(
		c.TechnicianMatchingRepo,
		c.Storage,
	)
	c.TechnicianMatchingHandler = technicianmatching.NewHandler(
		c.TechnicianMatchingService,
	)
}

func (c *Container) initTechnicianModule() {
	c.TechnicianRepo = technician.NewRepository(c.DB)
	c.TechnicianServiceAreaRepo = technicianservicearea.NewRepository(c.DB)
	c.TechnicianService = technician.NewService(
		c.DB,
		c.TechnicianRepo,
		c.TechnicianServiceAreaRepo,
		c.TechnicianServiceRepo,
	)
	c.TechnicianHandler = technician.NewHandler(c.TechnicianService, c.Storage)
}

func (c *Container) initTechnicianServiceModule() {
	c.TechnicianServiceRepo = technicianservice.NewRepository(c.DB)
	c.TechnicianServiceService = technicianservice.NewService(c.TechnicianServiceRepo)
	c.TechnicianServiceHandler = technicianservice.NewHandler(c.TechnicianServiceService)
}

func (c *Container) initServiceCategoryModule(cfg *config.Config) {
	c.ServiceCategoryRepo = servicecategory.NewRepository(c.DB)
	c.ServiceCategoryService = servicecategory.NewService(c.ServiceCategoryRepo)
	c.ServiceCategoryHandler = servicecategory.NewHandler(
		c.ServiceCategoryService,
		c.Storage,
		cfg,
	)
}

func (c *Container) initServiceModule() {
	c.ServiceRepo = service.NewRepository(c.DB)
	c.ServiceService = service.NewService(c.ServiceRepo)
	c.ServiceHandler = service.NewHandler(c.ServiceService)
}

func (c *Container) initBadgeModule() {
	c.BadgeRepo = badge.NewRepository(c.DB)
	c.BadgeService = badge.NewService(c.BadgeRepo)
	c.BadgeHandler = badge.NewRouteBundle(c.DB, c.Storage)
}

func (c *Container) initTechnicianBadgeModule() {
	c.TechnicianBadgeRepo = technicianbadge.NewRepository(c.DB)

	c.TechnicianBadgeService = technicianbadge.NewService(
		c.TechnicianBadgeRepo,
		c.TechnicianRepo,
	)

	c.TechnicianBadgeHandler = technicianbadge.NewHandler(c.TechnicianBadgeService)
}

func (c *Container) initTechnicianWorkModule() {
	c.TechnicianPostRepo = techworks.NewRepository(c.DB)
	c.TechnicianPostService = techworks.NewService(c.TechnicianPostRepo)
	c.TechnicianPostHandler = techworks.NewHandler(c.TechnicianPostService)
}

func (c *Container) initTechnicianAddressModule() {
	c.TechnicianAddressRepo = technicianaddress.NewRepository(c.DB)
	c.TechnicianAddressService = technicianaddress.NewService(
		c.TechnicianAddressRepo,
	)
	c.TechnicianAddressHandler = technicianaddress.NewHandler(c.TechnicianAddressService)
}

func AllModels() []interface{} {
	models := make([]interface{}, 0)

	models = append(models, auth.Models()...)

	models = append(models, province.Models()...)
	models = append(models, servicecategory.Models()...)
	models = append(models, service.Models()...)
	models = append(models, customer.Models()...)
	models = append(models, technician.Models()...)

	models = append(models, customeraddresses.Models()...)
	models = append(models, technicianservice.Models()...)
	models = append(models, technicianservicearea.Models()...)

	models = append(models, badge.Models()...)
	models = append(models, technicianbadge.Models()...)
	models = append(models, techworks.Models()...)
	models = append(models, technicianaddress.Models()...)

	return models
}
