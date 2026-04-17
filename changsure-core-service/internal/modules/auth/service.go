package auth

import (
	"context"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/jwtutil"
	"changsure-core-service/internal/modules/admin"
	criminalcheck "changsure-core-service/internal/modules/criminal_check"
	"changsure-core-service/internal/modules/customer"
	customeraddress "changsure-core-service/internal/modules/customer_address"
	"changsure-core-service/internal/modules/document"
	emailverification "changsure-core-service/internal/modules/email_verification"
	"changsure-core-service/internal/modules/notification"
	"changsure-core-service/internal/modules/technician"
	technicianaddress "changsure-core-service/internal/modules/technician_address"
	technicianpost "changsure-core-service/internal/modules/technician_post"
	technicianservice "changsure-core-service/internal/modules/technician_service"
	technicianarea "changsure-core-service/internal/modules/technician_service_area"
)

type Service interface {
	RegisterCustomer(ctx context.Context, req RegisterCustomerRequest) (*RegisterCustomerResponse, error)
	RegisterTechnician(ctx context.Context, req RegisterTechnicianRequest) (*RegisterTechnicianResponse, error)
	Login(ctx context.Context, req LoginRequest) (*LoginResponse, error)
	RefreshToken(ctx context.Context, req RefreshTokenRequest) (*RefreshTokenResponse, error)
	Logout(ctx context.Context, req LogoutRequest) error
}

type service struct {
	db              *gorm.DB
	cfg             TokenConfig
	tokenRepo       TokenRepository
	adminRepo       admin.Repository
	customerRepo    customer.Repository
	techRepo        technician.Repository
	custAddrRepo    customeraddress.Repository
	techAddrRepo    technicianaddress.Repository
	techServiceRepo technicianservice.Repository
	techAreaRepo    technicianarea.Repository
	criminalRepo    criminalcheck.Repository
	documentService document.Service
	notif           notification.Service
	emailChecker    EmailChecker
	phoneChecker    PhoneChecker
	otpService      emailverification.Service
}

func NewService(
	db *gorm.DB,
	cfg TokenConfig,
	tokenRepo TokenRepository,
	adminRepo admin.Repository,
	customerRepo customer.Repository,
	techRepo technician.Repository,
	custAddrRepo customeraddress.Repository,
	techAddrRepo technicianaddress.Repository,
	techServiceRepo technicianservice.Repository,
	techAreaRepo technicianarea.Repository,
	criminalRepo criminalcheck.Repository,
	documentService document.Service,
	notif notification.Service,
	otpService emailverification.Service,
) Service {
	return &service{
		db:              db,
		cfg:             cfg,
		tokenRepo:       tokenRepo,
		adminRepo:       adminRepo,
		customerRepo:    customerRepo,
		techRepo:        techRepo,
		custAddrRepo:    custAddrRepo,
		techAddrRepo:    techAddrRepo,
		techServiceRepo: techServiceRepo,
		techAreaRepo:    techAreaRepo,
		criminalRepo:    criminalRepo,
		documentService: documentService,
		notif:           notif,
		emailChecker:    NewEmailChecker(adminRepo, customerRepo, techRepo),
		phoneChecker:    NewPhoneChecker(customerRepo, techRepo),
		otpService:      otpService,
	}
}

func (s *service) isEmailTaken(ctx context.Context, email string) (bool, error) {
	return s.emailChecker.IsTaken(ctx, email, "", 0)
}

func (s *service) isPhoneTaken(ctx context.Context, phone string) (bool, error) {
	return s.phoneChecker.IsTaken(ctx, phone, "", 0)
}

func (s *service) RegisterCustomer(ctx context.Context, req RegisterCustomerRequest) (*RegisterCustomerResponse, error) {
	if taken, err := s.isEmailTaken(ctx, req.Email); err != nil {
		return nil, err
	} else if taken {
		return nil, appErrors.NewConflict(ErrEmailAlreadyExists.Error())
	}

	if taken, err := s.isPhoneTaken(ctx, req.Phone); err != nil {
		return nil, err
	} else if taken {
		return nil, appErrors.NewConflict(ErrPhoneAlreadyExists.Error())
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	cust := &customer.Customer{
		FirstName:    req.FirstName,
		LastName:     req.LastName,
		Email:        &req.Email,
		Phone:        &req.Phone,
		PasswordHash: string(hash),
	}

	var otpResult *emailverification.SendOTPResponse

	if err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(cust).Error; err != nil {
			return fmt.Errorf("create customer: %w", err)
		}
		if req.Address != nil {
			addr := buildCustomerAddress(cust.ID, *req.Address, true)
			if err := tx.Create(addr).Error; err != nil {
				return fmt.Errorf("create address: %w", err)
			}
		}

		if s.otpService != nil {
			resp, err := s.otpService.IssueOTP(ctx, cust.ID, req.Email, RoleCustomer)
			if err != nil {
				return fmt.Errorf("send OTP: %w", err)
			}
			otpResult = resp
		}

		return nil
	}); err != nil {
		return nil, err
	}

	resp := &RegisterCustomerResponse{
		CustomerID: cust.ID,
		Email:      req.Email,
		FirstName:  req.FirstName,
		LastName:   req.LastName,
		Role:       RoleCustomer,
		Message:    "สมัครสมาชิกสำเร็จ กรุณายืนยัน email ก่อน login",
	}

	if otpResult != nil && otpResult.OTP != nil {
		resp.OTP = otpResult.OTP
	}

	return resp, nil
}

func (s *service) RegisterTechnician(ctx context.Context, req RegisterTechnicianRequest) (*RegisterTechnicianResponse, error) {
	email := strings.ToLower(strings.TrimSpace(req.Email))
	phone := strings.TrimSpace(req.Phone)

	if taken, err := s.isEmailTaken(ctx, email); err != nil {
		return nil, fmt.Errorf("check email: %w", err)
	} else if taken {
		return nil, appErrors.NewConflict(ErrEmailAlreadyExists.Error())
	}

	if taken, err := s.isPhoneTaken(ctx, phone); err != nil {
		return nil, fmt.Errorf("check phone: %w", err)
	} else if taken {
		return nil, appErrors.NewConflict(ErrPhoneAlreadyExists.Error())
	}

	if len(req.Consents) == 0 {
		return nil, appErrors.NewBadRequest("consents are required")
	}

	if _, err := s.documentService.GetPublished("changsure-terms", "th"); err != nil {
		return nil, appErrors.NewBadRequest("terms document not available")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	now := time.Now().UTC()
	tech := &technician.Technician{
		FirstName:          req.FirstName,
		LastName:           req.LastName,
		Email:              &email,
		Phone:              &phone,
		PasswordHash:       string(hash),
		VerificationStatus: technician.StatusPending,
		IsAvailable:        false,
		CreatedAt:          now,
		UpdatedAt:          now,
	}

	var (
		preVerifiedToken string
		otpResult        *emailverification.SendOTPResponse
	)

	if err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(tech).Error; err != nil {
			return fmt.Errorf("create technician: %w", err)
		}
		if req.Address != nil {
			addr := buildTechnicianAddress(tech.ID, *req.Address, true)
			if err := tx.Create(addr).Error; err != nil {
				return fmt.Errorf("create address: %w", err)
			}
		}
		if len(req.Services) > 0 {
			if err := s.techServiceRepo.ReplaceAll(ctx, tx, tech.ID, req.Services); err != nil {
				return fmt.Errorf("create services: %w", err)
			}
		}
		if len(req.ProvinceIDs) > 0 {
			if err := s.techAreaRepo.ReplaceForTech(tx, tech.ID, req.ProvinceIDs); err != nil {
				return fmt.Errorf("create service areas: %w", err)
			}
		}
		if _, err := s.documentService.Accept("changsure-terms", tech.ID, RoleTechnician, "th", req.Consents); err != nil {
			return fmt.Errorf("accept terms: %w", err)
		}

		token, err := IssueAccessToken(TokenConfig{
			Secret:    s.cfg.Secret,
			AccessTTL: 15 * 24 * time.Hour,
		}, JWTClaims{
			UserID:             tech.ID,
			Email:              email,
			Role:               RoleTechnician,
			VerificationStatus: string(technician.StatusPending),
			Scope:              jwtutil.ScopePreVerified,
		})
		if err != nil {
			return fmt.Errorf("issue pre_verified_token: %w", err)
		}
		preVerifiedToken = token

		if s.otpService != nil {
			resp, err := s.otpService.IssueOTP(ctx, tech.ID, email, RoleTechnician)
			if err != nil {
				return fmt.Errorf("send OTP: %w", err)
			}
			otpResult = resp
		}

		return nil
	}); err != nil {
		if strings.Contains(err.Error(), "duplicate") {
			return nil, appErrors.NewConflict("duplicate data")
		}
		return nil, err
	}

	resp := &RegisterTechnicianResponse{
		TechnicianID:         tech.ID,
		Email:                email,
		FirstName:            req.FirstName,
		LastName:             req.LastName,
		Role:                 RoleTechnician,
		VerificationStatus:   string(technician.StatusPending),
		Message:              "สมัครสมาชิกสำเร็จ กรุณายืนยัน email ก่อน login",
		PreVerifiedToken:     preVerifiedToken,
		PreVerifiedExpiresIn: int64((15 * 24 * time.Hour).Seconds()),
		NextStep: NextStepInfo{
			Action:   "verify_email",
			Endpoint: "/api/auth/verify-email",
			Method:   "POST",
		},
	}

	if otpResult != nil && otpResult.OTP != nil {
		resp.OTP = otpResult.OTP
	}

	return resp, nil
}

func (s *service) Login(ctx context.Context, req LoginRequest) (*LoginResponse, error) {

	if a, err := s.adminRepo.FindByEmail(ctx, req.Email); err == nil && a != nil {
		return s.loginAsAdmin(ctx, a, req.Password)
	}

	if cust, err := s.customerRepo.FindByEmail(ctx, req.Email); err == nil && cust != nil {
		return s.loginAsCustomer(ctx, cust, req.Password)
	}

	if tech, err := s.techRepo.FindByEmail(ctx, req.Email); err == nil && tech != nil {
		return s.loginAsTechnician(ctx, tech, req.Password)
	}

	return nil, appErrors.NewUnauthorized(ErrInvalidCredentials.Error())
}

func (s *service) loginAsAdmin(ctx context.Context, a *admin.Admin, password string) (*LoginResponse, error) {
	if err := bcrypt.CompareHashAndPassword([]byte(a.PasswordHash), []byte(password)); err != nil {
		return nil, appErrors.NewUnauthorized(ErrInvalidCredentials.Error())
	}
	return s.issueTokens(ctx, JWTClaims{
		UserID:             a.ID,
		Email:              a.Email,
		Role:               RoleAdmin,
		VerificationStatus: string(technician.StatusApproved),
	}, a.FirstName, a.LastName, nil)
}

func (s *service) loginAsCustomer(ctx context.Context, cust *customer.Customer, password string) (*LoginResponse, error) {

	if err := bcrypt.CompareHashAndPassword([]byte(cust.PasswordHash), []byte(password)); err != nil {
		return nil, appErrors.NewUnauthorized(ErrInvalidCredentials.Error())
	}

	if cust.EmailVerifiedAt == nil {
		return nil, appErrors.NewForbidden("กรุณายืนยัน email ก่อน login")
	}

	return s.issueTokens(ctx, JWTClaims{
		UserID:             cust.ID,
		Email:              *cust.Email,
		Role:               RoleCustomer,
		VerificationStatus: string(technician.StatusApproved),
	}, cust.FirstName, cust.LastName, nil)
}

func (s *service) loginAsTechnician(ctx context.Context, tech *technician.Technician, password string) (*LoginResponse, error) {
	if err := bcrypt.CompareHashAndPassword([]byte(tech.PasswordHash), []byte(password)); err != nil {
		return nil, appErrors.NewUnauthorized(ErrInvalidCredentials.Error())
	}

	if tech.EmailVerifiedAt == nil {
		return nil, appErrors.NewForbidden("กรุณายืนยัน email ก่อน login")
	}

	if tech.BannedAt != nil && s.notif != nil {
		expiresAt := tech.BannedAt.Add(time.Duration(technicianpost.RestrictGracePeriodDays) * 24 * time.Hour)
		if time.Now().Before(expiresAt) {
			remaining := expiresAt.Sub(time.Now())
			days := int(math.Floor(remaining.Hours() / 24))
			go s.notif.Create(ctx, notification.CreateNotificationInput{
				RecipientRole: notification.RoleTechnician,
				RecipientID:   tech.ID,
				Type:          "ACCOUNT_BANNED",
				Title:         "บัญชีของคุณถูกระงับการรับงาน ⚠️",
				Message: fmt.Sprintf(
					"บัญชีของคุณถูกระงับการรับงานชั่วคราว เหลืออีก %d วัน (%s) กรุณาติดต่อทีมงานหากมีข้อสงสัย",
					days,
					expiresAt.In(time.FixedZone("ICT", 7*60*60)).Format("02 Jan 2006 15:04"),
				),
				Data: map[string]any{
					"banned_at":      tech.BannedAt.Unix(),
					"expires_at":     expiresAt.Unix(),
					"remaining_days": days,
				},
			})
		}
	}

	if tech.VerificationStatus == technician.StatusApproved {
		return s.issueTokens(ctx, JWTClaims{
			UserID:             tech.ID,
			Email:              *tech.Email,
			Role:               RoleTechnician,
			VerificationStatus: string(tech.VerificationStatus),
		}, tech.FirstName, tech.LastName, tech.BannedAt)
	}

	if tech.VerificationStatus == technician.StatusPending && s.criminalRepo != nil {
		logs, err := s.criminalRepo.GetLogsByTechnicianID(tech.ID)
		if err == nil && len(logs) > 0 {
			latest := logs[0]
			if latest.Status == criminalcheck.StatusPending ||
				latest.Status == criminalcheck.StatusNameMismatch {
				return s.issueTokens(ctx, JWTClaims{
					UserID:             tech.ID,
					Email:              *tech.Email,
					Role:               RoleTechnician,
					VerificationStatus: string(tech.VerificationStatus),
				}, tech.FirstName, tech.LastName, tech.BannedAt)
			}
		}
	}

	return nil, s.resolveVerificationError(ctx, tech.ID)
}

func (s *service) resolveVerificationError(ctx context.Context, techID uint) error {
	if s.criminalRepo == nil {
		return appErrors.NewForbidden(ErrTechnicianNotVerified.Error())
	}
	logs, err := s.criminalRepo.GetLogsByTechnicianID(techID)
	if err != nil || len(logs) == 0 {
		return appErrors.NewForbidden(ErrTechnicianNotVerified.Error())
	}
	latest := logs[0]
	switch latest.Status {
	case criminalcheck.StatusRejected:
		msg := ErrTechnicianVerifyFailed.Error()
		if latest.Note != "" {
			msg = fmt.Sprintf("%s: %s", msg, latest.Note)
		}
		return appErrors.NewForbidden(msg)
	case criminalcheck.StatusOCRFailed:
		return appErrors.NewForbidden("ID card verification failed — please re-upload your ID card")
	default:
		return appErrors.NewForbidden(ErrTechnicianNotVerified.Error())
	}
}

func (s *service) issueTokens(ctx context.Context, claims JWTClaims, firstName, lastName string, bannedAt *time.Time) (*LoginResponse, error) {
	accessToken, refreshToken, err := IssueTokenPair(s.cfg, claims)
	if err != nil {
		return nil, fmt.Errorf("issue tokens: %w", err)
	}
	if err := s.tokenRepo.Save(ctx, &RefreshToken{
		UserID:    claims.UserID,
		Role:      claims.Role,
		Token:     refreshToken,
		ExpiresAt: time.Now().Add(s.cfg.RefreshTTLDuration()),
	}); err != nil {
		return nil, fmt.Errorf("save refresh token: %w", err)
	}

	var banInfo *BanInfo
	if bannedAt != nil {
		expiresAt := bannedAt.Add(time.Duration(technicianpost.RestrictGracePeriodDays) * 24 * time.Hour)
		now := time.Now()
		if now.Before(expiresAt) {
			remaining := expiresAt.Sub(now)
			totalHours := remaining.Hours()
			banInfo = &BanInfo{
				BannedAt:         bannedAt.Unix(),
				ExpiresAt:        expiresAt.Unix(),
				RemainingDays:    int(math.Floor(totalHours / 24)),
				RemainingHours:   int(math.Floor(totalHours)) % 24,
				RemainingMinutes: int(remaining.Minutes()) % 60,
				Message:          "บัญชีของคุณถูกระงับการรับงานชั่วคราว กรุณาติดต่อทีมงานหากมีข้อสงสัย",
			}
		}
	}

	return &LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    AccessTTLSeconds(s.cfg),
		User: UserInfo{
			ID:                 claims.UserID,
			Email:              claims.Email,
			FirstName:          firstName,
			LastName:           lastName,
			Role:               claims.Role,
			VerificationStatus: claims.VerificationStatus,
			BanInfo:            banInfo,
		},
	}, nil
}

func (s *service) RefreshToken(ctx context.Context, req RefreshTokenRequest) (*RefreshTokenResponse, error) {
	stored, err := s.tokenRepo.FindByToken(ctx, req.RefreshToken)
	if err != nil {
		if errors.Is(err, ErrRefreshTokenNotFound) {
			return nil, appErrors.NewUnauthorized("refresh token is invalid or expired")
		}
		return nil, fmt.Errorf("find refresh token: %w", err)
	}
	parsed, err := jwtutil.Parse(s.cfg.Secret, req.RefreshToken)
	if err != nil {
		return nil, appErrors.NewUnauthorized("refresh token is invalid or expired")
	}
	if parsed.TokenType != TokenTypeRefresh {
		return nil, appErrors.NewUnauthorized("token type must be refresh")
	}
	updatedClaims, err := s.syncUserClaims(ctx, stored.UserID, stored.Role)
	if err != nil {
		return nil, fmt.Errorf("sync user claims: %w", err)
	}
	newAccessToken, err := IssueAccessToken(s.cfg, *updatedClaims)
	if err != nil {
		return nil, fmt.Errorf("issue access token: %w", err)
	}
	return &RefreshTokenResponse{
		AccessToken: newAccessToken,
		TokenType:   "Bearer",
		ExpiresIn:   AccessTTLSeconds(s.cfg),
	}, nil
}

func (s *service) syncUserClaims(ctx context.Context, userID uint, role string) (*JWTClaims, error) {
	switch role {
	case RoleAdmin:
		a, err := s.adminRepo.FindByID(ctx, userID)
		if err != nil || a == nil {
			return nil, appErrors.NewUnauthorized("user not found")
		}
		return &JWTClaims{
			UserID:             a.ID,
			Email:              a.Email,
			Role:               RoleAdmin,
			VerificationStatus: string(technician.StatusApproved),
		}, nil
	case RoleCustomer:
		cust, err := s.customerRepo.FindByID(ctx, userID)
		if err != nil || cust == nil {
			return nil, appErrors.NewUnauthorized("user not found")
		}
		return &JWTClaims{
			UserID:             cust.ID,
			Email:              *cust.Email,
			Role:               RoleCustomer,
			VerificationStatus: string(technician.StatusApproved),
		}, nil
	case RoleTechnician:
		tech, err := s.techRepo.FindByID(ctx, userID)
		if err != nil || tech == nil {
			return nil, appErrors.NewUnauthorized("user not found")
		}
		return &JWTClaims{
			UserID:             tech.ID,
			Email:              *tech.Email,
			Role:               RoleTechnician,
			VerificationStatus: string(tech.VerificationStatus),
		}, nil
	default:
		return nil, appErrors.NewUnauthorized(ErrInvalidRole.Error())
	}
}

func (s *service) Logout(ctx context.Context, req LogoutRequest) error {
	if err := s.tokenRepo.Revoke(ctx, req.RefreshToken); err != nil {
		if errors.Is(err, ErrRefreshTokenNotFound) {
			return nil
		}
		return fmt.Errorf("revoke token: %w", err)
	}
	return nil
}

func buildCustomerAddress(custID uint, req customeraddress.CreateCustomerAddressRequest, defaultPrimary bool) *customeraddress.CustomerAddress {
	isPrimary := defaultPrimary
	if req.IsPrimary != nil {
		isPrimary = *req.IsPrimary
	}
	addr := &customeraddress.CustomerAddress{CustomerID: custID}
	addr.Label = req.Label
	addr.PhoneNumber = req.PhoneNumber
	addr.AddressLine = req.AddressLine
	addr.HouseNumber = req.HouseNumber
	addr.Village = req.Village
	addr.Moo = req.Moo
	addr.Soi = req.Soi
	addr.Road = req.Road
	addr.SubDistrictID = req.SubDistrictID
	addr.DistrictID = req.DistrictID
	addr.ProvinceID = req.ProvinceID
	addr.Latitude = req.Latitude
	addr.Longitude = req.Longitude
	addr.IsPrimary = isPrimary
	return addr
}

func buildTechnicianAddress(techID uint, req technicianaddress.CreateTechnicianAddressRequest, defaultPrimary bool) *technicianaddress.TechnicianAddress {
	isPrimary := defaultPrimary
	if req.IsPrimary != nil {
		isPrimary = *req.IsPrimary
	}
	addr := &technicianaddress.TechnicianAddress{TechnicianID: techID}
	addr.Label = req.Label
	addr.PhoneNumber = req.PhoneNumber
	addr.AddressLine = req.AddressLine
	addr.HouseNumber = req.HouseNumber
	addr.Village = req.Village
	addr.Moo = req.Moo
	addr.Soi = req.Soi
	addr.Road = req.Road
	addr.SubDistrictID = req.SubDistrictID
	addr.DistrictID = req.DistrictID
	addr.ProvinceID = req.ProvinceID
	addr.Latitude = req.Latitude
	addr.Longitude = req.Longitude
	addr.IsPrimary = isPrimary
	return addr
}
