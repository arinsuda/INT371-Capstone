package technicians

type Technician struct {
	ID          int    `gorm:"primaryKey;autoIncrement" json:"id"`
	DisplayName string `gorm:"type:varchar(100);not null" json:"display_name"`
	Province_ID int    `gorm:"not null" json:"province_id"`
	Latitude    string `gorm:"type:decimal(10,7);not null" json:"latitude"`
	Longitude   string `gorm:"type:decimal(10,7);not null" json:"longitude"`
	Rating      string `gorm:"type:decimal(3,2);default:0.0" json:"rating"`

	CreatedAt   int64  `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   int64  `gorm:"autoUpdateTime" json:"updated_at"`
}
