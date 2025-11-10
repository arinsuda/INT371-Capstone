package database

import (
	"fmt"
	"log"

	"changsure-core-service/internal/modules/provinces"
	"changsure-core-service/internal/modules/service_categories"
	"changsure-core-service/internal/modules/services"
)

func (d *Database) Seed() error {
	log.Println("🌱 Seeding database...")

	seeders := []func() error{
		d.seedProvinces,
		d.seedServiceCategories,
		d.seedServices,
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

func (d *Database) seedServices() error {
	var count int64
	if err := d.DB.Model(&services.Service{}).Count(&count).Error; err != nil {
		return fmt.Errorf("count services: %w", err)
	}
	if count > 0 {
		log.Println("   ⊘ Services already seeded, skipping")
		return nil
	}

	var cats []service_categories.ServiceCategory
	if err := d.DB.Find(&cats).Error; err != nil {
		return fmt.Errorf("read service categories: %w", err)
	}
	catID := map[string]uint{}
	for _, c := range cats {
		catID[c.CatName] = c.ID
	}

	requiredCats := []string{
		"งานไฟฟ้าและเครื่องใช้ไฟฟ้า",
		"งานประปา",
		"งานทาสี",
		"งานซ่อมบำรุงทั่วไป",
	}
	for _, name := range requiredCats {
		if _, ok := catID[name]; !ok {
			return fmt.Errorf("missing service category %q, seedServiceCategories must run first", name)
		}
	}

	type item struct {
		Cat  string
		Name string
		Desc *string
		Img  *string
	}

	items := []item{
		// ===== งานทาสี =====
		{Cat: "งานทาสี", Name: "ทาสีภายในอาคาร"},
		{Cat: "งานทาสี", Name: "ทาสีภายนอกอาคาร"},
		{Cat: "งานทาสี", Name: "ทาสีรั้วบ้าน"},
		{Cat: "งานทาสี", Name: "ทาสีหลังคา (แบบ Bager กับ Synotex)"},
		{Cat: "งานทาสี", Name: "ทาสีเฟอร์นิเจอร์ไม้"},
		{Cat: "งานทาสี", Name: "สำรวจทาสี"},

		// ===== งานประปา =====
		{Cat: "งานประปา", Name: "ซ่อมท่อน้ำรั่ว / ท่อแตก"},
		{Cat: "งานประปา", Name: "ติดตั้งอ่างล้างหน้า"},
		{Cat: "งานประปา", Name: "ล้างถังพักน้ำ / แทงก์น้ำ"},
		{Cat: "งานประปา", Name: "ติดตั้งปั๊มน้ำ"},
		{Cat: "งานประปา", Name: "ติดตั้งสุขภัณฑ์ธรรมดา"},
		{Cat: "งานประปา", Name: "ติดตั้งสุขภัณฑ์อัตโนมัติ"},
		{Cat: "งานประปา", Name: "ซ่อมท่ออุดตัน / ส้วมตัน"},
		{Cat: "งานประปา", Name: "ติดตั้งเครื่องทำน้ำอุ่น (แบบเดิน)"},
		{Cat: "งานประปา", Name: "ติดตั้งเครื่องทำน้ำอุ่น (แบบจั๊ม)"},

		// ===== งานไฟฟ้าและเครื่องใช้ไฟฟ้า – กลุ่มไฟฟ้า =====
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ติดตั้งปลั๊กไฟ / สวิตช์ไฟ"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "เปลี่ยนปลั๊กไฟ / สวิตช์ไฟ"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ติดตั้งเบรกเกอร์"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ซ่อมไฟไม่ติด / ไฟช็อต"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ตรวจสอบระบบไฟฟ้าในบ้าน"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ติดตั้งพัดลมติดผนัง"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ติดตั้งพัดลมดูดอากาศ"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "เปลี่ยนดาวน์ไลท์ / ไฟเพดาน"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ติดตั้งไฟฉุกเฉิน"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ติดตั้งกล้องวงจรปิด"},

		// ===== งานไฟฟ้าและเครื่องใช้ไฟฟ้า – กลุ่มเครื่องใช้ไฟฟ้า =====
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ซ่อมแอร์"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ล้างแอร์"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ซ่อมตู้เย็น"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ซ่อมเครื่องซักผ้า / เครื่องอบผ้า"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ซ่อมเตาอบ / เตาไมโครเวฟ"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ซ่อมทีวี ขนาด 19 - 35 นิ้ว"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ซ่อมทีวี ขนาด 36 - 60 นิ้ว"},
		{Cat: "งานไฟฟ้าและเครื่องใช้ไฟฟ้า", Name: "ซ่อมทีวี ขนาดมากกว่า 60 นิ้ว"},
	}

	records := make([]services.Service, 0, len(items))
	for _, it := range items {
		cid := catID[it.Cat]
		records = append(records, services.Service{
			SerName:        it.Name,
			SerDescription: it.Desc,
			ImageURL:       it.Img,
			IsActive:       true,
			CategoryID:     cid,
		})
	}

	if err := d.DB.Create(&records).Error; err != nil {
		return fmt.Errorf("seed services: %w", err)
	}

	log.Printf("   ✓ Seeded %d services", len(records))
	return nil
}
