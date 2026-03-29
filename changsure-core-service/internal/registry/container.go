package registry

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"time"

	"github.com/gofiber/fiber/v3"
	"gorm.io/gorm"

	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/modules/admin"
	"changsure-core-service/internal/modules/auth"
	backgroundjob "changsure-core-service/internal/modules/background_job"
	"changsure-core-service/internal/modules/badge"
	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/internal/modules/chat"
	criminalcheck "changsure-core-service/internal/modules/criminal_check"
	customer "changsure-core-service/internal/modules/customer"
	customeraddresses "changsure-core-service/internal/modules/customer_address"
	customerbooking "changsure-core-service/internal/modules/customer_booking"
	customerreview "changsure-core-service/internal/modules/customer_review"
	"changsure-core-service/internal/modules/dashboard"
	"changsure-core-service/internal/modules/district"
	"changsure-core-service/internal/modules/document"
	"changsure-core-service/internal/modules/notification"
	ocrhandler "changsure-core-service/internal/modules/ocr/handler"
	ocrinfra "changsure-core-service/internal/modules/ocr/infra"
	ocrservice "changsure-core-service/internal/modules/ocr/service"
	"changsure-core-service/internal/modules/payment"
	"changsure-core-service/internal/modules/province"
	resetpassword "changsure-core-service/internal/modules/reset_password"
	"changsure-core-service/internal/modules/service"
	servicecategory "changsure-core-service/internal/modules/service_category"
	subdistrict "changsure-core-service/internal/modules/sub_district"
	"changsure-core-service/internal/modules/technician"
	technicianaddress "changsure-core-service/internal/modules/technician_address"
	technicianbadge "changsure-core-service/internal/modules/technician_badge"
	technicianbooking "changsure-core-service/internal/modules/technician_booking"
	techniciancalendar "changsure-core-service/internal/modules/technician_calendar"
	technicianmatching "changsure-core-service/internal/modules/technician_matching"
	techworks "changsure-core-service/internal/modules/technician_post"
	technicianreview "changsure-core-service/internal/modules/technician_review"
	technicianservice "changsure-core-service/internal/modules/technician_service"
	technicianservicearea "changsure-core-service/internal/modules/technician_service_area"
	timeslot "changsure-core-service/internal/modules/time_slot"
	"changsure-core-service/internal/modules/wallet"
	"changsure-core-service/internal/realtime"

	"changsure-core-service/internal/config"
	"changsure-core-service/pkg/mailer"
	"changsure-core-service/pkg/storage"
)

type ContainerOption func(*Container) error

type Container struct {
	DB      *gorm.DB
	Storage *storage.MinioStorage
	Hub     *realtime.Hub
	Logger  *slog.Logger

	AuthRepo    auth.RefreshTokenRepository
	AuthService auth.Service
	AuthHandler *auth.Handler

	NotificationRepo    notification.Repository
	NotificationService notification.Service
	NotificationHandler *notification.Handler

	CustomerRepo    customer.Repository
	CustomerService customer.Service
	CustomerHandler *customer.Handler

	CustomerAddressRepo    customeraddresses.Repository
	CustomerAddressService customeraddresses.Service
	CustomerAddressHandler *customeraddresses.Handler

	TechnicianMatchingRepo    technicianmatching.Repository
	TechnicianMatchingService technicianmatching.Service
	TechnicianMatchingHandler *technicianmatching.Handler

	TimeSlotRepo    timeslot.Repository
	TimeSlotService timeslot.Service
	TimeSlotHandler *timeslot.Handler

	BookingRepo booking.Repository

	CustomerBookingService customerbooking.Service
	CustomerBookingHandler *customerbooking.Handler

	TechnicianBookingService technicianbooking.Service
	TechnicianBookingHandler *technicianbooking.Handler

	ProvinceRepo    province.Repository
	ProvinceService province.Service
	ProvinceHandler *province.Handler

	DistrictRepo    district.Repository
	DistrictService district.Service
	DistrictHandler *district.Handler

	SubDistrictRepo    subdistrict.Repository
	SubDistrictService subdistrict.Service
	SubDistrictHandler *subdistrict.Handler

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

	TechnicianCalendarRepo    techniciancalendar.Repository
	TechnicianCalendarService techniciancalendar.Service
	TechnicianCalendarHandler *techniciancalendar.Handler

	ChatRepo    chat.Repository
	ChatService chat.Service
	ChatHandler *chat.Handler

	PaymentRepo    payment.Repository
	PaymentTxnRepo payment.PaymentTransactionRepository
	PaymentService payment.Service
	PaymentHandler *payment.Handler

	WalletRepo    wallet.Repository
	WalletService wallet.Service
	WalletHandler *wallet.Handler

	OCRService ocrservice.OCRService
	OCRHandler *ocrhandler.OCRHandler

	DocumentRepo    document.Repository
	DocumentService document.Service
	DocumentHandler *document.Handler

	ResetPasswordRepo    resetpassword.Repository
	ResetPasswordService resetpassword.Service
	ResetPasswordHandler *resetpassword.Handler

	BackgroundJobRepo backgroundjob.Repository

	CriminalCheckRepo    criminalcheck.Repository
	CriminalCheckService criminalcheck.Service
	CriminalCheckHandler *criminalcheck.Handler

	Mailer                  mailer.Mailer
	CustomerReviewHandler   *customerreview.Handler
	TechnicianReviewHandler *technicianreview.Handler

	AdminHandler *admin.Handler
	AdminRepo    admin.Repository

	DashboardRepo    dashboard.Repository
	DashboardService dashboard.Service
	DashboardHandler *dashboard.Handler
}

func NewContainer(db *gorm.DB, cfg *config.Config, hub *realtime.Hub, opts ...ContainerOption) (*Container, error) {
	if db == nil {
		return nil, fmt.Errorf("database connection is required")
	}
	if cfg == nil {
		return nil, fmt.Errorf("configuration is required")
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	c := &Container{
		DB:     db,
		Hub:    hub,
		Logger: logger,
	}

	if err := c.initStorage(cfg); err != nil {
		return nil, err
	}
	c.initAdminModule()
	c.initProvinceModule()
	c.initDistrictModule()
	c.initSubDistrictModule()
	c.initTechnicianServiceModule()
	c.initTechnicianModule()
	c.initTechnicianAddressModule()
	c.initCustomerModule()
	c.initCustomerAddressModule()
	c.initDocumentModule()
	c.initAuthModule(cfg)
	c.initNotificationModule()
	c.initOCRModule(cfg)
	c.initServiceCategoryModule(cfg)
	c.initServiceModule()
	c.initBadgeModule()
	c.initTechnicianBadgeModule()
	c.initTechnicianWorkModule()
	c.initTechnicianMatchingModule()
	c.initTimeSlotModule()
	c.initBookingCoreModule()
	c.initTechnicianCalendarModule()
	c.initCustomerBookingModule()
	c.initTechnicianBookingModule()
	c.initCustomerReviewModule()
	c.initTechnicianReviewModule()
	c.initChatModule()
	c.initWalletModule()
	c.initPaymentModule(cfg)
	c.initMailer(cfg)
	c.initResetPasswordModule(cfg)
	c.initBackgroundJobModule()
	c.initCriminalCheckModule()
	c.initDashboardModule()

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

	tokenRepo := auth.NewTokenRepository(c.DB)

	tokenCfg := auth.TokenConfig{
		Secret:     []byte(cfg.JWT.Secret),
		AccessTTL:  time.Duration(cfg.JWT.AccessTokenTTL) * time.Second,
		RefreshTTL: time.Duration(cfg.JWT.RefreshTokenTTL) * time.Second,
	}

	c.AuthService = auth.NewService(
		c.DB,
		tokenCfg,
		tokenRepo,
		c.AdminRepo,
		c.CustomerRepo,
		c.TechnicianRepo,
		c.CustomerAddressRepo,
		c.TechnicianAddressRepo,
		c.TechnicianServiceRepo,
		c.TechnicianServiceAreaRepo,
		c.CriminalCheckRepo,
		c.DocumentService,
	)

	c.AuthHandler = auth.NewHandler(c.AuthService)
	cleaner := auth.NewCleaner(c.DB, tokenRepo, 7*24*time.Hour, c.Logger)
	cleaner.StartBackground(context.Background(), 24*time.Hour)
}

func (c *Container) initNotificationModule() {
	c.NotificationRepo = notification.NewRepository(c.DB)
	c.NotificationService = notification.NewService(c.NotificationRepo, c.Hub)

	getAuthUser := func(ctx fiber.Ctx) (notification.AuthUser, bool) {
		uid, ok := middleware.GetUserID(ctx)
		if !ok {
			return notification.AuthUser{}, false
		}
		roleAny := ctx.Locals("role")
		roleStr, ok := roleAny.(string)
		if !ok {
			return notification.AuthUser{}, false
		}
		return notification.AuthUser{
			ID:   uid,
			Role: notification.RecipientRole(roleStr),
		}, true
	}

	c.NotificationHandler = notification.NewHandler(c.NotificationService, getAuthUser)
}

func (c *Container) initOCRModule(cfg *config.Config) {
	client := ocrinfra.NewOCRClient(cfg.OCR.BaseURL)
	c.OCRService = ocrservice.NewOCRService(client)
	c.OCRHandler = ocrhandler.NewOCRHandler(c.OCRService)
}

func (c *Container) initCustomerModule() {
	c.CustomerRepo = customer.NewRepository(c.DB)
	c.CustomerService = customer.NewService(c.CustomerRepo, c.Storage, c.Logger)
	c.CustomerHandler = customer.NewHandler(c.CustomerService, c.Storage, c.Logger)
}

func (c *Container) initProvinceModule() {
	c.ProvinceRepo = province.NewRepository(c.DB)
	c.ProvinceService = province.NewService(c.ProvinceRepo)
	c.ProvinceHandler = province.NewHandler(c.ProvinceService)
}

func (c *Container) initDistrictModule() {
	c.DistrictRepo = district.NewRepository(c.DB)
	c.DistrictService = district.NewService(c.DistrictRepo)
	c.DistrictHandler = district.NewHandler(c.DistrictService)
}

func (c *Container) initSubDistrictModule() {
	c.SubDistrictRepo = subdistrict.NewRepository(c.DB)
	c.SubDistrictService = subdistrict.NewService(c.SubDistrictRepo)
	c.SubDistrictHandler = subdistrict.NewHandler(c.SubDistrictService)
}

func (c *Container) initCustomerAddressModule() {
	c.CustomerAddressRepo = customeraddresses.NewRepository(c.DB)
	c.CustomerAddressService = customeraddresses.NewService(
		c.CustomerAddressRepo,
		c.DistrictRepo,
		c.SubDistrictRepo,
	)
	c.CustomerAddressHandler = customeraddresses.NewHandler(c.CustomerAddressService)
}

func (c *Container) initTechnicianMatchingModule() {
	c.TechnicianMatchingRepo = technicianmatching.NewRepository(c.DB)
	c.TechnicianMatchingService = technicianmatching.NewService(
		c.TechnicianMatchingRepo,
		c.Storage,
	)
	c.TechnicianMatchingHandler = technicianmatching.NewHandler(c.TechnicianMatchingService, c.TechnicianService)
}

func (c *Container) initTechnicianModule() {
	c.TechnicianRepo = technician.NewRepository(c.DB)
	c.TechnicianServiceAreaRepo = technicianservicearea.NewRepository(c.DB)
	c.TechnicianService = technician.NewService(
		c.DB,
		c.TechnicianRepo,
		c.TechnicianServiceAreaRepo,
		c.TechnicianServiceRepo,
		c.DocumentRepo,
		c.Storage,
		c.TechnicianAddressRepo,
		c.Logger,
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
	c.BadgeService = badge.NewService(c.BadgeRepo, c.Storage)
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
	c.TechnicianPostService = techworks.NewService(c.TechnicianPostRepo, c.Storage, c.NotificationService)
	c.TechnicianPostHandler = techworks.NewHandler(c.TechnicianPostService)
}

func (c *Container) initTechnicianAddressModule() {
	c.TechnicianAddressRepo = technicianaddress.NewRepository(c.DB)
	c.TechnicianAddressService = technicianaddress.NewService(
		c.TechnicianAddressRepo,
		c.DistrictRepo,
		c.SubDistrictRepo,
	)
	c.TechnicianAddressHandler = technicianaddress.NewHandler(c.TechnicianAddressService)
}

func (c *Container) initTimeSlotModule() {
	c.TimeSlotRepo = timeslot.NewRepository(c.DB)
	c.TimeSlotService = timeslot.NewService(c.TimeSlotRepo)
	c.TimeSlotHandler = timeslot.NewHandler(c.TimeSlotService)
}

func (c *Container) initBookingCoreModule() {
	c.BookingRepo = booking.NewRepository(c.DB)
}

func (c *Container) initCustomerBookingModule() {
	if c.BookingRepo == nil {
		panic("customer_booking: BookingRepo must be initialized first")
	}
	if c.TimeSlotRepo == nil {
		panic("customer_booking: TimeSlotRepo is required")
	}
	if c.TechnicianCalendarRepo == nil {
		panic("customer_booking: TechnicianCalendarRepo is required")
	}

	c.CustomerBookingService = customerbooking.NewService(
		c.BookingRepo,
		c.TimeSlotRepo,
		c.TechnicianCalendarRepo,
		c.DB,
		c.NotificationService,
		c.Logger,
	)
	c.CustomerBookingHandler = customerbooking.NewHandler(
		c.CustomerBookingService,
		c.Storage,
		c.Hub,
		c.Logger,
	)
}

func (c *Container) initTechnicianBookingModule() {
	if c.BookingRepo == nil {
		panic("technician_booking: BookingRepo must be initialized first")
	}

	c.TechnicianBookingService = technicianbooking.NewService(
		c.BookingRepo,
		c.DB,
		c.NotificationService,
		c.TechnicianRepo,
	)
	c.TechnicianBookingHandler = technicianbooking.NewHandler(
		c.TechnicianBookingService,
		c.Storage,
		c.Hub,
	)
}

func (c *Container) initTechnicianCalendarModule() {
	if c.BookingRepo == nil {
		panic("technician_calendar: BookingRepo must be initialized first")
	}
	if c.TimeSlotRepo == nil {
		panic("technician_calendar: TimeSlotRepo must be initialized first")
	}

	c.TechnicianCalendarRepo = techniciancalendar.NewRepository(c.DB)
	c.TechnicianCalendarService = techniciancalendar.NewService(
		c.TechnicianCalendarRepo,
		c.BookingRepo,
		c.TimeSlotRepo,
		c.Storage,
		c.Logger,
	)
	c.TechnicianCalendarHandler = techniciancalendar.NewHandler(
		c.TechnicianCalendarService,
		c.Logger,
	)
}

func (c *Container) initChatModule() {
	if c.BookingRepo == nil {
		panic("chat: BookingRepo must be initialized first")
	}
	if c.Hub == nil {
		panic("chat: RealtimeHub is required")
	}
	if c.Storage == nil {
		panic("chat: Storage is required")
	}

	c.ChatRepo = chat.NewRepository(c.DB, c.Storage)
	c.ChatService = chat.NewService(
		c.ChatRepo,
		c.BookingRepo,
		c.Hub,
		c.Storage,
	)
	c.ChatHandler = chat.NewHandler(c.ChatService)
}

func (c *Container) initWalletModule() {
	c.WalletRepo = wallet.NewRepository(c.DB)
	c.WalletService = wallet.NewService(c.WalletRepo, c.DB, wallet.DefaultConfig())
	c.WalletHandler = wallet.NewHandler(c.WalletRepo, c.WalletService, c.TechnicianRepo)
}

func (c *Container) initPaymentModule(cfg *config.Config) {
	if c.WalletRepo == nil {
		panic("payment: WalletRepo must be initialized first (call initWalletModule before initPaymentModule)")
	}
	if c.BookingRepo == nil {
		panic("payment: BookingRepo must be initialized first")
	}

	omiseCfg := config.OmiseConfig{
		PublicKey:       cfg.Omise.PublicKey,
		SecretKey:       cfg.Omise.SecretKey,
		WebhookSecret:   cfg.Omise.WebhookSecret,
		Currency:        cfg.Omise.Currency,
		Timeout:         cfg.Omise.Timeout,
		QRExpiryMinutes: cfg.Omise.QRExpiryMinutes,
	}

	repo, err := payment.NewOmiseRepository(omiseCfg)
	if err != nil {
		panic(fmt.Sprintf("payment: failed to init omise repo: %v", err))
	}
	c.PaymentRepo = repo
	c.PaymentTxnRepo = payment.NewPaymentTransactionRepository(c.DB)

	svc, err := payment.NewService(
		c.PaymentRepo,
		c.BookingRepo,
		c.PaymentTxnRepo,
		c.TechnicianServiceService,
		c.WalletRepo,
		c.DB,
		cfg.Wallet.PlatformFeeRate,
		payment.Config{Omise: omiseCfg},
		nil,
	)
	if err != nil {
		panic(fmt.Sprintf("payment: failed to init service: %v", err))
	}
	c.PaymentService = svc

	isDev := cfg.App.Environment == "development"
	c.PaymentHandler = payment.NewHandler(
		c.PaymentService,
		c.Hub,
		cfg.Omise.WebhookSecret,
		isDev,
		c.Logger,
	)
}

func (c *Container) initDocumentModule() {
	c.DocumentRepo = document.NewRepository(c.DB)
	c.DocumentService = document.NewService(c.DocumentRepo, c.DB)
	c.DocumentHandler = document.NewHandler(c.DocumentService)
}

func (c *Container) initMailer(cfg *config.Config) {
	c.Mailer = mailer.New(mailer.Config{
		Host:     cfg.Mailer.Host,
		Port:     cfg.Mailer.Port,
		Username: cfg.Mailer.Username,
		Password: cfg.Mailer.Password,
		From:     cfg.Mailer.From,
		FromName: cfg.Mailer.FromName,
	})
}

func (c *Container) initResetPasswordModule(cfg *config.Config) {
	c.ResetPasswordRepo = resetpassword.NewRepository(c.DB)
	c.ResetPasswordService = resetpassword.NewService(
		c.ResetPasswordRepo,
		c.CustomerRepo,
		c.TechnicianRepo,
		c.Mailer,
		cfg.JWT.Secret,
		cfg.App.Environment == "development",
	)
	c.ResetPasswordHandler = resetpassword.NewHandler(c.ResetPasswordService)
}

func (c *Container) initBackgroundJobModule() {
	c.BackgroundJobRepo = backgroundjob.NewRepository(c.DB)
}

func (c *Container) initCriminalCheckModule() {
	repo := criminalcheck.NewRepository(c.DB)
	c.CriminalCheckService = criminalcheck.NewService(
		repo,
		c.TechnicianRepo,
		c.OCRService,
		c.NotificationService,
		c.BackgroundJobRepo,
		c.Storage,
	)
	c.CriminalCheckHandler = criminalcheck.NewHandler(c.CriminalCheckService)
}

func (c *Container) initAdminModule() {
	c.AdminRepo = admin.NewRepository(c.DB)
	adminSvc := admin.NewService(c.AdminRepo, c.Storage)
	c.AdminHandler = admin.NewHandler(adminSvc)
}

func (c *Container) initCustomerReviewModule() {
	if c.BookingRepo == nil {
		panic("customer_review: BookingRepo must be initialized first")
	}
	reviewService := customerreview.NewService(c.BookingRepo)
	c.CustomerReviewHandler = customerreview.NewHandler(reviewService, c.Storage)
}

func (c *Container) initTechnicianReviewModule() {
	if c.BookingRepo == nil {
		panic("technician_review: BookingRepo must be initialized first")
	}
	reviewService := technicianreview.NewService(c.BookingRepo)
	c.TechnicianReviewHandler = technicianreview.NewHandler(reviewService, c.Storage)
}

func (c *Container) initDashboardModule() {
	c.DashboardRepo = dashboard.NewRepository(c.DB)
	c.DashboardService = dashboard.NewService(c.DashboardRepo, c.Storage)
	c.DashboardHandler = dashboard.NewHandler(c.DashboardService)
}

func AllModels() []interface{} {
	models := make([]interface{}, 0)
	models = append(models, auth.Models()...)
	models = append(models, notification.Models()...)
	models = append(models, province.Models()...)
	models = append(models, district.Models()...)
	models = append(models, subdistrict.Models()...)
	models = append(models, servicecategory.Models()...)
	models = append(models, service.Models()...)
	models = append(models, customer.Models()...)
	models = append(models, customeraddresses.Models()...)
	models = append(models, technician.Models()...)
	models = append(models, technicianaddress.Models()...)
	models = append(models, technicianservice.Models()...)
	models = append(models, technicianservicearea.Models()...)
	models = append(models, technicianbadge.Models()...)
	models = append(models, techworks.Models()...)
	models = append(models, techniciancalendar.Models()...)
	models = append(models, badge.Models()...)
	models = append(models, booking.Models()...)
	models = append(models, timeslot.Models()...)
	models = append(models, chat.Models()...)
	models = append(models,
		&payment.PaymentTransaction{},
		&payment.PaymentEvent{},
	)
	models = append(models, wallet.Models()...)
	models = append(models, document.Models()...)
	models = append(models, resetpassword.Models()...)
	models = append(models, criminalcheck.Models()...)
	models = append(models, admin.Models()...)
	models = append(models, backgroundjob.Models()...)
	models = append(models, wallet.Models()...)

	return models
}
