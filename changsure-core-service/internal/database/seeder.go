package database

import (
	"fmt"
	"log"

	"changsure-core-service/internal/modules/provinces"
	"changsure-core-service/internal/modules/reservation_statuses"
)

func (d *Database) Seed() error {
	log.Println("🌱 Seeding database...")

	seeders := []func() error{
		d.seedProvinces,
		d.seedReservationStatuses,
	}

	for _, seeder := range seeders {
		if err := seeder(); err != nil {
			return err
		}
	}

	log.Println("✅ Seeding completed successfully")
	return nil
}

func strPtr(s string) *string { return &s }

func (d *Database) seedProvinces() error {
	var count int64

	d.DB.Model(&provinces.Province{}).Count(&count)
	if count > 0 {
		log.Println("   ⊘ Provinces already seeded, skipping")
		return nil
	}

	data := []provinces.Province{
		{
			NameTH: "กรุงเทพมหานคร",
			NameEN: strPtr("Bangkok"),
			Region: strPtr("Central"),
		},
		{
			NameTH: "เชียงใหม่",
			NameEN: strPtr("Chiang Mai"),
			Region: strPtr("North"),
		},
		{
			NameTH: "ชลบุรี",
			NameEN: strPtr("Chonburi"),
			Region: strPtr("East"),
		},
	}

	if err := d.DB.Create(&data).Error; err != nil {
		return fmt.Errorf("seed provinces: %w", err)
	}

	log.Printf("   ✓ Seeded %d provinces", len(data))
	return nil
}

func (d *Database) seedReservationStatuses() error {
	var count int64
	d.DB.Model(&reservation_statuses.ReservationStatus{}).Count(&count)
	if count > 0 {
		log.Println("   ⊘ Reservation statuses already seeded, skipping")
		return nil
	}

	data := []reservation_statuses.ReservationStatus{
		{Code: "pending", Name: "Pending", Description: "Waiting for confirmation"},
		{Code: "confirmed", Name: "Confirmed", Description: "Confirmed by technician"},
		{Code: "in_progress", Name: "In Progress", Description: "Service is ongoing"},
		{Code: "completed", Name: "Completed", Description: "Service completed"},
		{Code: "cancelled", Name: "Cancelled", Description: "Cancelled by customer or technician"},
	}

	if err := d.DB.Create(&data).Error; err != nil {
		return fmt.Errorf("seed reservation statuses: %w", err)
	}

	log.Printf("   ✓ Seeded %d reservation statuses", len(data))
	return nil
}
