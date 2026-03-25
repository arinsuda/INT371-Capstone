package auth

import (
	"context"
	"errors"
	"fmt"
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
	"changsure-core-service/internal/modules/technician"
	technicianaddress "changsure-core-service/internal/modules/technician_address"
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
	}
}

func (s *service) isEmailTaken(ctx context.Context, email string) (bool, error) {
	if a, err := s.adminRepo.FindByEmail(ctx, email); err != nil {
		return false, fmt.Errorf("check admin email: %w", err)
	} else if a != nil {
		return true, nil
	}

	if c, err := s.customerRepo.FindByEmail(ctx, email); err != nil {
		return false, fmt.Errorf("check customer email: %w", err)
	} else if c != nil {
		return true, nil
	}

	if t, err := s.techRepo.FindByEmail(ctx, email); err != nil {
		return false, fmt.Errorf("check technician email: %w", err)
	} else if t != nil {
		return true, nil
	}

	return false, nil
}

func (s *service) isPhoneTaken(ctx context.Context, phone string) (bool, error) {

	if c, err := s.customerRepo.FindByPhone(ctx, phone); err != nil {
		return false, fmt.Errorf("check customer phone: %w", err)
	} else if c != nil {
		return true, nil
	}

	if t, err := s.techRepo.FindByPhone(ctx, phone); err != nil {
		return false, fmt.Errorf("check technician phone: %w", err)
	} else if t != nil {
		return true, nil
	}

	return false, nil
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

	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(cust).Error; err != nil {
			return fmt.Errorf("create customer: %w", err)
		}
		if req.Address != nil {
			addr := buildCustomerAddress(cust.ID, *req.Address, true)
			if err := tx.Create(addr).Error; err != nil {
				return fmt.Errorf("create address: %w", err)
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	return &RegisterCustomerResponse{
		CustomerID: cust.ID,
		Email:      req.Email,
		FirstName:  req.FirstName,
		LastName:   req.LastName,
		Role:       RoleCustomer,
		Message:    "สมัครสมาชิกสำเร็จ",
	}, nil
}

func (s *service) RegisterTechnician(ctx context.Context, req RegisterTechnicianRequest) (*RegisterTechnicianResponse, error) {

	email := strings.ToLower(strings.TrimSpace(req.Email))
	phone := strings.TrimSpace(req.Phone)

	if taken, err := s.isEmailTaken(ctx, email); err != nil {
		return nil, err
	} else if taken {
		return nil, appErrors.NewConflict(ErrEmailAlreadyExists.Error())
	}

	if taken, err := s.isPhoneTaken(ctx, phone); err != nil {
		return nil, err
	} else if taken {
		return nil, appErrors.NewConflict(ErrPhoneAlreadyExists.Error())
	}

	if len(req.Consents) == 0 {
		return nil, appErrors.NewBadRequest("consents are required")
	}

	if _, err := s.documentService.GetPublished("terms", "th"); err != nil {
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

	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {

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

		if _, err := s.documentService.Accept(
			"terms",
			tech.ID,
			RoleTechnician,
			"th",
			req.Consents,
		); err != nil {
			return fmt.Errorf("accept terms: %w", err)
		}

		return nil
	})
	if err != nil {
		return nil, err
	}

	preVerifiedCfg := TokenConfig{
		Secret:    s.cfg.Secret,
		AccessTTL: 15 * 24 * time.Hour,
	}

	preVerifiedToken, err := IssueAccessToken(preVerifiedCfg, JWTClaims{
		UserID:             tech.ID,
		Email:              email,
		Role:               RoleTechnician,
		VerificationStatus: string(technician.StatusPending),
		Scope:              jwtutil.ScopePreVerified,
	})
	if err != nil {
		return nil, fmt.Errorf("issue pre_verified token: %w", err)
	}

	return &RegisterTechnicianResponse{
		TechnicianID:         tech.ID,
		Email:                email,
		FirstName:            req.FirstName,
		LastName:             req.LastName,
		Role:                 RoleTechnician,
		VerificationStatus:   string(technician.StatusPending),
		Message:              "สมัครสมาชิกสำเร็จ กรุณาอัปโหลดบัตรประชาชนเพื่อยืนยันตัวตน",
		PreVerifiedToken:     preVerifiedToken,
		PreVerifiedExpiresIn: preVerifiedCfg.AccessTTLSeconds(),
		NextStep: NextStepInfo{
			Action:   "upload_id_card",
			Endpoint: fmt.Sprintf("/api/technicians/%d/verify-identity", tech.ID),
			Method:   "POST",
		},
	}, nil
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
		VerificationStatus: string(technician.StatusPassed),
	}, a.FirstName, a.LastName)
}

func (s *service) loginAsCustomer(ctx context.Context, cust *customer.Customer, password string) (*LoginResponse, error) {
	if err := bcrypt.CompareHashAndPassword([]byte(cust.PasswordHash), []byte(password)); err != nil {
		return nil, appErrors.NewUnauthorized(ErrInvalidCredentials.Error())
	}
	return s.issueTokens(ctx, JWTClaims{
		UserID:             cust.ID,
		Email:              *cust.Email,
		Role:               RoleCustomer,
		VerificationStatus: string(technician.StatusPassed),
	}, cust.FirstName, cust.LastName)
}

func (s *service) loginAsTechnician(ctx context.Context, tech *technician.Technician, password string) (*LoginResponse, error) {

	if err := bcrypt.CompareHashAndPassword([]byte(tech.PasswordHash), []byte(password)); err != nil {
		return nil, appErrors.NewUnauthorized(ErrInvalidCredentials.Error())
	}

	if !tech.IsAvailable && tech.BannedAt != nil {
		return nil, appErrors.NewForbidden(ErrTechnicianBanned.Error())
	}

	if tech.VerificationStatus == technician.StatusPassed {
		return s.issueTokens(ctx, JWTClaims{
			UserID:             tech.ID,
			Email:              *tech.Email,
			Role:               RoleTechnician,
			VerificationStatus: string(tech.VerificationStatus),
		}, tech.FirstName, tech.LastName)
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
	case criminalcheck.StatusFailed:

		msg := ErrTechnicianVerifyFailed.Error()
		if latest.Note != "" {
			msg = fmt.Sprintf("%s: %s", msg, latest.Note)
		}
		return appErrors.NewForbidden(msg)

	case criminalcheck.StatusPending,
		criminalcheck.StatusNameNotExtracted:

		return appErrors.NewForbidden(ErrTechnicianVerifyPending.Error())

	case criminalcheck.StatusOCRFailed:

		return appErrors.NewForbidden(
			"ID card verification failed — please re-upload your ID card",
		)

	default:

		return appErrors.NewForbidden(ErrTechnicianNotVerified.Error())
	}
}

func (s *service) issueTokens(ctx context.Context, claims JWTClaims, firstName, lastName string) (*LoginResponse, error) {
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
			VerificationStatus: string(technician.StatusPassed),
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
			VerificationStatus: string(technician.StatusPassed),
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
