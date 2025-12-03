package technician

import (
	"time"

	technicianaddress "changsure-core-service/internal/modules/technician_service_area"
	technicianbadge "changsure-core-service/internal/modules/technician_badge"
	tsvc "changsure-core-service/internal/modules/technician_service"
)

type Technician struct {
	ID        uint    `gorm:"primaryKey;autoIncrement" json:"id"`
	FirstName string  `gorm:"type:varchar(150);not null" json:"firstname"`
	LastName  string  `gorm:"type:varchar(150);not null" json:"lastname"`
	Bio       *string `gorm:"type:text" json:"bio"`
	Phone     *string `gorm:"type:varchar(10)" json:"phone"`

	Email        *string `gorm:"type:varchar(100);uniqueIndex" json:"email"`
	PasswordHash string  `gorm:"type:varchar(255);not null" json:"-"`

	AvatarURL   *string    `gorm:"type:varchar(255)" json:"avatar_url"`
	RatingAvg   *float64   `gorm:"type:decimal(3,2);default:0.0" json:"rating_avg"`
	RatingCount uint       `gorm:"default:0" json:"rating_count"`
	TotalJobs   uint       `gorm:"default:0" json:"total_jobs"`
	IsAvailable bool       `gorm:"default:true" json:"is_available"`
	IsVerified  bool       `gorm:"default:false" json:"is_verified"`
	CreatedAt   time.Time  `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time  `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt   *time.Time `gorm:"index" json:"-"`

	ServiceAreas []technicianaddress.TechnicianServiceArea `gorm:"foreignKey:TechnicianID" json:"service_areas,omitempty"`
	Badges       []technicianbadge.TechnicianBadge          `gorm:"foreignKey:TechnicianID" json:"badges,omitempty"`
	Services []tsvc.TechnicianService `gorm:"foreignKey:TechnicianID" json:"services,omitempty"`
}

func (Technician) TableName() string { return "technicians" }

func Models() []interface{} {
	return []interface{}{&Technician{}}
}
