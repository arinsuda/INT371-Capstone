package service

import (
	servicecategory "changsure-core-service/internal/modules/service_category"
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"
)

type StringArray []string

func (sa StringArray) Value() (driver.Value, error) {
	return json.Marshal(sa)
}

func (sa *StringArray) Scan(value interface{}) error {
	if value == nil {
		*sa = []string{}
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return errors.New("failed to unmarshal StringArray value")
	}

	return json.Unmarshal(bytes, sa)
}

type JSONMap map[string]interface{}

func (j JSONMap) Value() (driver.Value, error) {
	return json.Marshal(j)
}

func (j *JSONMap) Scan(value interface{}) error {
	if value == nil {
		*j = JSONMap{}
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return errors.New("failed to unmarshal JSONMap value")
	}

	return json.Unmarshal(bytes, j)
}

type Service struct {
	ID              uint        `gorm:"primaryKey;autoIncrement" json:"id"`
	SerName         string      `gorm:"column:ser_name;type:varchar(190);not null" json:"ser_name"`
	SerDescription  *string     `gorm:"column:ser_description;type:text" json:"ser_description"`
	SerDetails      StringArray `gorm:"column:ser_details;type:json" json:"ser_details"`
	AdditionalTerms StringArray `gorm:"column:additional_terms;type:json" json:"additional_terms"`
	WorkingDuration StringArray `gorm:"column:working_duration;type:json" json:"working_duration"`
	ImageURLs       StringArray `gorm:"column:image_urls;type:json" json:"image_urls"`

	IsActive  bool      `gorm:"column:is_active;not null;default:true;index:idx_services_category_active,priority:2" json:"is_active"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`

	DefaultPrice JSONMap `gorm:"column:default_price;type:json" json:"default_price"`

	CategoryID uint                                `gorm:"column:category_id;not null;index:idx_services_category_active,priority:1" json:"category_id"`
	Category   *servicecategory.ServiceCategory `gorm:"foreignKey:CategoryID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT" json:"category,omitempty"`
}

func (Service) TableName() string { return "services" }

func Models() []interface{} {
	return []interface{}{
		&Service{},
	}
}
