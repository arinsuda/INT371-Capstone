package database

import (
	"fmt"
	"log"

	"changsure-core-service/internal/modules/provinces"
	"changsure-core-service/internal/modules/service_categories"
)

func (d *Database) Seed() error {
	log.Println("🌱 Seeding database...")

	seeders := []func() error{
		d.seedProvinces,
		d.seedServiceCategories,
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

func (d *Database) seedServiceCategories() error {
	var count int64
	d.DB.Model(&service_categories.ServiceCategory{}).Count(&count)
	if count > 0 {
		log.Println("   ⊘ Service categories already seeded, skipping")
		return nil
	}

	ptr := func(s string) *string { return &s }

	data := []service_categories.ServiceCategory{
		{
			CatName: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า",
			CatDesc: ptr("บริการเกี่ยวกับระบบไฟฟ้า การเดินสาย ติดตั้งปลั๊กไฟ ซ่อมแอร์ และซ่อมเครื่องใช้ไฟฟ้าทั่วไป"),
		},
		{
			CatName: "งานประปา",
			CatDesc: ptr("บริการซ่อมและติดตั้งระบบประปา แก้ไขท่อรั่ว ติดตั้งสุขภัณฑ์ และตรวจสอบระบบน้ำ"),
		},
		{
			CatName: "งานทาสี",
			CatDesc: ptr("บริการทาสีอาคาร บ้าน ที่พักอาศัย ภายนอก-ภายใน รวมถึงงานรีโนเวทผนัง"),
		},
		{
			CatName: "งานซ่อมบำรุงทั่วไป",
			CatDesc: ptr("บริการซ่อมแซมอุปกรณ์ทั่วไป เช่น เฟอร์นิเจอร์ ประตู หน้าต่าง หรืองานบำรุงรักษาอื่นๆ"),
		},
	}

	if err := d.DB.Create(&data).Error; err != nil {
		return fmt.Errorf("seed service categories: %w", err)
	}

	log.Printf("   ✓ Seeded %d service categories", len(data))
	return nil
}
