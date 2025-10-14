package provinces

type Province struct {
	ID     uint    `gorm:"primaryKey;autoIncrement"`
	NameTH string  `gorm:"type:varchar(100);uniqueIndex;not null"`
	NameEN *string `gorm:"type:varchar(100)"`
	Region *string `gorm:"type:varchar(50)"`
}

func (Province) TableName() string { return "provinces" }

func Models() []interface{} {
	return []interface{}{
		&Province{},
	}
}
