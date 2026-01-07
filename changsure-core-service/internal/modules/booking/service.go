package booking

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	address "changsure-core-service/internal/modules/customer_address"
	technicianschedule "changsure-core-service/internal/modules/technician_schedule"
	timeslot "changsure-core-service/internal/modules/time_slot"

	"gorm.io/gorm"
)

var (
	ErrSlotBooked            = errors.New("time slot is already booked")
	ErrServiceNotFound       = errors.New("technician service not found")
	ErrAddressNotFound       = errors.New("address not found or invalid ownership")
	ErrInvalidDateFormat     = errors.New("invalid date format")
	ErrTechnicianClosed      = errors.New("technician is not working on this date")
	ErrInvalidTimeSlot       = errors.New("time slot is invalid or changed")
	ErrServiceAreaNotCovered = errors.New("technician does not serve this area")
)

var bkkLoc *time.Location

func init() {
	var err error
	bkkLoc, err = time.LoadLocation("Asia/Bangkok")
	if err != nil {
		bkkLoc = time.Local
	}
}

type Service interface {
	GetAvailableTimeSlots(ctx context.Context, technicianID uint, dateStr string) ([]TimeSlotAvailability, error)

	CreateBooking(ctx context.Context, customerID uint, req CreateBookingRequest) (*Booking, error)
	GetBookingDetail(ctx context.Context, bookingID uint) (*Booking, error)
}

type service struct {
	repo         Repository
	timeSlotRepo timeslot.Repository
	scheduleRepo technicianschedule.Repository
	db           *gorm.DB
}

func NewService(repo Repository, timeSlotRepo timeslot.Repository, scheduleRepo technicianschedule.Repository, db *gorm.DB) Service {
	return &service{
		repo:         repo,
		timeSlotRepo: timeSlotRepo,
		scheduleRepo: scheduleRepo,
		db:           db,
	}
}

func (s *service) GetAvailableTimeSlots(ctx context.Context, technicianID uint, dateStr string) ([]TimeSlotAvailability, error) {
	if _, err := time.ParseInLocation("2006-01-02", dateStr, bkkLoc); err != nil {
		return nil, ErrInvalidDateFormat
	}

	allSlots, err := s.timeSlotRepo.GetSlotsForTechnician(ctx, technicianID)
	if err != nil {
		return nil, err

	}

	bookedSlotIDs, err := s.repo.GetBookedSlotIDs(ctx, technicianID, dateStr)
	if err != nil {
		return nil, err
	}

	bookedMap := make(map[uint]bool, len(bookedSlotIDs))
	for _, id := range bookedSlotIDs {
		bookedMap[id] = true
	}

	result := make([]TimeSlotAvailability, 0, len(allSlots))
	for _, slot := range allSlots {
		result = append(result, TimeSlotAvailability{
			ID:          slot.ID,
			Label:       fmt.Sprintf("%s - %s", slot.StartTime, slot.EndTime),
			IsAvailable: !bookedMap[slot.ID],
		})
	}

	return result, nil
}

func (s *service) CreateBooking(ctx context.Context, customerID uint, req CreateBookingRequest) (*Booking, error) {

	appointDate, err := time.ParseInLocation("2006-01-02", req.AppointmentDate, bkkLoc)
	if err != nil {
		return nil, ErrInvalidDateFormat
	}
	dateStr := req.AppointmentDate

	// ==========================================
	// 🛡️ VALIDATION PHASE
	// ==========================================

	// 1. ✅ เช็คว่าช่างทำงานวันนั้นไหม (Weekly Schedule)
	weekday := int(appointDate.Weekday()) // 0=Sun, 1=Mon
	workingDays, err := s.scheduleRepo.GetWeeklySchedule(ctx, req.TechnicianID)
	if err != nil {
		return nil, err
	}
	isWorkingDay := false
	if len(workingDays) == 0 {
		isWorkingDay = true // Default ถ้าไม่ตั้งค่าคือทำทุกวัน
	} else {
		for _, day := range workingDays {
			if day == weekday {
				isWorkingDay = true
				break
			}
		}
	}
	if !isWorkingDay {
		return nil, ErrTechnicianClosed
	}

	// 2. ✅ เช็คว่าวันนั้นลาไหม (Leave Date)
	// ใช้ GetLeavesByRange แบบวันเดียว (Start=End)
	leavesMap, err := s.scheduleRepo.GetLeavesByRange(ctx, req.TechnicianID, dateStr, dateStr)
	if err != nil {
		return nil, err
	}
	if leavesMap[dateStr] {
		return nil, ErrTechnicianClosed
	}

	// 3. ✅ เช็ค Time Slot Consistency (ป้องกันเคสช่างเปลี่ยนเวลาชนกับลูกค้าจอง)
	targetSlot, err := s.timeSlotRepo.FindByID(ctx, req.TimeSlotID)
	if err != nil {
		// ถ้าหา ID ไม่เจอ แสดงว่าช่างลบไปแล้ว
		return nil, ErrInvalidTimeSlot
	}

	// เช็คว่าเป็น Slot ของช่างคนนี้จริงไหม (หรือเป็น Default)
	if targetSlot.TechnicianID != nil && *targetSlot.TechnicianID != req.TechnicianID {
		return nil, ErrInvalidTimeSlot
	}
	// เช็คว่า Active ไหม
	if !targetSlot.IsActive {
		return nil, ErrInvalidTimeSlot
	}

	// ==========================================
	// 💾 TRANSACTION PHASE
	// ==========================================

	var newBooking *Booking

	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		txRepo := s.repo.WithTx(tx)

		// 4. เช็ค Double Booking (เหมือนเดิม)
		isBooked, err := txRepo.IsSlotBooked(ctx, req.TechnicianID, req.AppointmentDate, req.TimeSlotID)
		if err != nil {
			return err
		}
		if isBooked {
			return ErrSlotBooked
		}

		techSvc, err := txRepo.GetTechnicianService(ctx, req.TechnicianServiceID)
		if err != nil {
			return ErrServiceNotFound
		}
		finalPrice := getFinalPrice(techSvc.PriceFixed, techSvc.PriceMin)

		custAddr, err := txRepo.GetCustomerAddress(ctx, req.AddressID, customerID)
		if err != nil {
			return ErrAddressNotFound
		}

		if custAddr.ProvinceID != nil {
			isServing, err := txRepo.IsTechnicianServingProvince(ctx, req.TechnicianID, *custAddr.ProvinceID)
			if err != nil {
				return err
			}
			if !isServing {
				return ErrServiceAreaNotCovered
			}
		}

		fullAddress := formatAddressSnapshot(custAddr)

		newBooking = &Booking{
			CustomerID:          customerID,
			TechnicianID:        req.TechnicianID,
			TechnicianServiceID: req.TechnicianServiceID,
			AddressID:           req.AddressID,
			TimeSlotID:          req.TimeSlotID,
			AppointmentDate:     appointDate,
			PriceAmount:         finalPrice,
			RecordedAddress:     fullAddress,
			CustomerNote:        req.CustomerNote,
			Status:              BookingStatusPending,
			PaymentMethod:       PaymentMethodCOD,
		}

		if err := txRepo.Create(ctx, newBooking); err != nil {
			if strings.Contains(err.Error(), "Duplicate entry") || strings.Contains(err.Error(), "unique constraint") {
				return ErrSlotBooked
			}
			return err
		}

		if len(req.ImageURLs) > 0 {
			images := make([]BookingImage, 0, len(req.ImageURLs))
			for _, url := range req.ImageURLs {
				images = append(images, BookingImage{
					BookingID: newBooking.ID,
					ImageURL:  url,
				})
			}
			if err := txRepo.CreateImages(ctx, images); err != nil {
				return err
			}
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	created, err := s.repo.FindByID(ctx, newBooking.ID)
	if err != nil {
		return newBooking, nil
	}
	return created, nil
}

func (s *service) GetBookingDetail(ctx context.Context, bookingID uint) (*Booking, error) {
	return s.repo.FindByID(ctx, bookingID)
}

func getFinalPrice(fixed *float64, min *float64) float64 {
	if fixed != nil {
		return *fixed
	}
	if min != nil {
		return *min
	}
	return 0.0
}

func formatAddressSnapshot(addr *address.CustomerAddress) string {
	subName := "-"
	distName := "-"
	provName := "-"
	postal := "-"

	if addr.SubDistrict != nil {
		subName = addr.SubDistrict.NameTH
		postal = addr.SubDistrict.PostalCode
	}
	if addr.District != nil {
		distName = addr.District.NameTH
	}
	if addr.Province != nil {
		provName = addr.Province.NameTH
	}

	return fmt.Sprintf("%s หมู่บ้าน %s ซอย %s ถนน %s แขวง %s เขต %s จ. %s %s",
		getValue(addr.HouseNumber),
		getValue(addr.Village),
		getValue(addr.Soi),
		getValue(addr.Road),
		subName,
		distName,
		provName,
		postal,
	)
}

func getValue(s *string) string {
	if s == nil {
		return "-"
	}
	return *s
}
