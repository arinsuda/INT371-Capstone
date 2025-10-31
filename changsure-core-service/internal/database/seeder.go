package database

import (
	"fmt"
	"log"

	"changsure-core-service/internal/modules/provinces"
)

func (d *Database) Seed() error {
	log.Println("🌱 Seeding database...")

	seeders := []func() error{
		d.seedProvinces,
		// d.seedReservationStatuses,
	}

	for _, seeder := range seeders {
		if err := seeder(); err != nil {
			return err
		}
	}

	log.Println("✅ Seeding completed successfully")
	return nil
}

func (d *Database) seedProvinces() error {
	var count int64
	d.DB.Model(&provinces.Province{}).Count(&count)
	if count > 0 {
		log.Println("   ⊘ Provinces already seeded, skipping")
		return nil
	}

	names := []string{
		"กรุงเทพมหานคร", "กระบี่", "กาญจนบุรี", "กาฬสินธุ์", "กำแพงเพชร", "ขอนแก่น", "จันทบุรี", "ฉะเชิงเทรา", "ชลบุรี", "ชัยนาท", "ชัยภูมิ",
		"ชุมพร", "เชียงราย", "เชียงใหม่", "ตรัง", "ตราด", "ตาก", "นครนายก", "นครปฐม", "นครพนม", "นครราชสีมา", "นครศรีธรรมราช", "นครสวรรค์",
		"นนทบุรี", "นราธิวาส", "น่าน", "บึงกาฬ", "บุรีรัมย์", "ปทุมธานี", "ประจวบคีรีขันธ์", "ปราจีนบุรี", "ปัตตานี", "พระนครศรีอยุธยา",
		"พังงา", "พัทลุง", "พิจิตร", "พิษณุโลก", "เพชรบุรี", "เพชรบูรณ์", "แพร่", "พะเยา", "ภูเก็ต", "มหาสารคาม", "มุกดาหาร", "แม่ฮ่องสอน",
		"ยโสธร", "ยะลา", "ร้อยเอ็ด", "ระนอง", "ระยอง", "ราชบุรี", "ลพบุรี", "ลำปาง", "ลำพูน", "เลย", "ศรีสะเกษ", "สกลนคร", "สงขลา", "สตูล",
		"สมุทรปราการ", "สมุทรสงคราม", "สมุทรสาคร", "สระแก้ว", "สระบุรี", "สิงห์บุรี", "สุโขทัย", "สุพรรณบุรี", "สุราษฎร์ธานี", "สุรินทร์",
		"หนองคาย", "หนองบัวลำภู", "อ่างทอง", "อำนาจเจริญ", "อุดรธานี", "อุตรดิตถ์", "อุทัยธานี", "อุบลราชธานี",
	}

	data := make([]provinces.Province, 0, len(names))
	for _, n := range names {
		data = append(data, provinces.Province{NameTH: n})
	}

	if err := d.DB.Create(&data).Error; err != nil {
		return fmt.Errorf("seed provinces: %w", err)
	}

	log.Printf("   ✓ Seeded %d provinces", len(data))
	return nil
}

// func (d *Database) seedReservationStatuses() error {
// 	var count int64
// 	d.DB.Model(&reservation_statuses.ReservationStatus{}).Count(&count)
// 	if count > 0 {
// 		log.Println("   ⊘ Reservation statuses already seeded, skipping")
// 		return nil
// 	}

// 	data := []reservation_statuses.ReservationStatus{
// 		{Code: "pending", Name: "Pending", Description: "Waiting for confirmation"},
// 		{Code: "confirmed", Name: "Confirmed", Description: "Confirmed by technician"},
// 		{Code: "in_progress", Name: "In Progress", Description: "Service is ongoing"},
// 		{Code: "completed", Name: "Completed", Description: "Service completed"},
// 		{Code: "cancelled", Name: "Cancelled", Description: "Cancelled by customer or technician"},
// 	}

// 	if err := d.DB.Create(&data).Error; err != nil {
// 		return fmt.Errorf("seed reservation statuses: %w", err)
// 	}

// 	log.Printf("   ✓ Seeded %d reservation statuses", len(data))
// 	return nil
// }
