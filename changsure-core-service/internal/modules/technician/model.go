package technician

import (
	"time"

	technicianaddress "changsure-core-service/internal/modules/technician_address"
	technicianbadge "changsure-core-service/internal/modules/technician_badge"
	tsvc "changsure-core-service/internal/modules/technician_service"
	technicianarea "changsure-core-service/internal/modules/technician_service_area"
)

type Technician struct {
	ID        uint    `gorm:"primaryKey;autoIncrement" json:"id"`
	AvatarURL *string `gorm:"type:varchar(500)" json:"avatar_url"`
	FirstName string  `gorm:"type:varchar(150);not null" json:"firstname"`
	LastName  string  `gorm:"type:varchar(150);not null" json:"lastname"`
	Phone     *string `gorm:"type:varchar(10)" json:"phone"`
	Bio       *string `gorm:"type:text" json:"bio"`

	Email        *string `gorm:"type:varchar(100);uniqueIndex" json:"email"`
	PasswordHash string  `gorm:"type:varchar(255);not null" json:"-"`

	IsAvailable    bool    `gorm:"default:true" json:"is_available"`
	IsVerified     bool    `gorm:"default:false" json:"is_verified"`
	IDCardImageURL *string `gorm:"type:varchar(500)" json:"-"`

	CreatedAt time.Time  `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time  `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt *time.Time `gorm:"index" json:"-"`
	BannedAt  *time.Time `gorm:"index" json:"banned_at,omitempty"`

	RatingAvg   *float64 `gorm:"-" json:"rating_avg,omitempty"`
	RatingCount int64    `gorm:"-" json:"rating_count"`
	TotalJobs   int64    `gorm:"-" json:"total_jobs"`

	Addresses []technicianaddress.TechnicianAddress `gorm:"foreignKey:TechnicianID" json:"addresses,omitempty"`

	ServiceAreas []technicianarea.TechnicianServiceArea `gorm:"foreignKey:TechnicianID" json:"service_areas,omitempty"`
	Badges       []technicianbadge.TechnicianBadge      `gorm:"foreignKey:TechnicianID" json:"badges,omitempty"`
	Services     []tsvc.TechnicianService               `gorm:"foreignKey:TechnicianID" json:"services,omitempty"`
}

func (Technician) TableName() string { return "technicians" }

func Models() []interface{} {
	return []interface{}{&Technician{}}
}
