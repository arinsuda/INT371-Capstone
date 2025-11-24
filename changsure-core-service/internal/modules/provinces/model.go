package provinces

import "time"

type Province struct {
	ID        uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	NameTH    string    `gorm:"type:varchar(100);not null;uniqueIndex" json:"name_th"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

func (Province) TableName() string { return "provinces" }

func Models() []interface{} {
	return []interface{}{
		&Province{},
	}
}
