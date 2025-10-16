package reservation_statuses

type ReservationStatus struct {
	ID   uint   `gorm:"primaryKey;autoIncrement"`
	Code string `gorm:"type:varchar(20);uniqueIndex;not null"`
	Name string `gorm:"type:varchar(50);not null"`
	Description string `gorm:"type:varchar(255)"`
}

func (ReservationStatus) TableName() string { return "reservation_statuses" }

func Models() []interface{} {
	return []interface{}{
		&ReservationStatus{},
	}
}
