export type Technician = {
  id: number
  name: string
  email: string
  phone: string
  type: string
  area: string
  status: string
  verify: string
  date?: string
}

export const technicians: Technician[] = [
  {
    id: 1,
    name: "สมชาย ใจดี",
    email: "somchai.tech@gmail.com",
    phone: "089-123-4567",
    type: "การไฟฟ้า",
    area: "กรุงเทพมหานคร",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-01"
  },
  {
    id: 2,
    name: "วิชัย พงษ์สุข",
    email: "wichai.fix@gmail.com",
    phone: "081-234-8899",
    type: "ทาสี / การไฟฟ้า",
    area: "นนทบุรี",
    status: "ปกติ",
    verify: "รอการตรวจสอบ",
    date: "2026-03-05"
  },
  {
    id: 3,
    name: "ธนกร มณีวงศ์",
    email: "thanakorn.tech@gmail.com",
    phone: "091-442-8877",
    type: "ทาสี",
    area: "สมุทรปราการ",
    status: "ตักเตือน",
    verify: "ไม่ผ่าน",
    date: "2026-02-20"
  },
  {
    id: 4,
    name: "ภาคินัย พลสวัสดิ์",
    email: "phakin.service@gmail.com",
    phone: "093-887-4455",
    type: "การไฟฟ้า",
    area: "กรุงเทพมหานคร",
    status: "แบนถาวร",
    verify: "ไม่ผ่าน",
    date: "2026-01-15"
  },

  // ===== เพิ่ม =====
  {
    id: 5,
    name: "กิตติพงษ์ แสงทอง",
    email: "kitti.tech@gmail.com",
    phone: "082-111-2233",
    type: "ประปา",
    area: "ปทุมธานี",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-10"
  },
  {
    id: 6,
    name: "ชาญชัย วัฒนะ",
    email: "chan.fix@gmail.com",
    phone: "086-222-3344",
    type: "ทาสี",
    area: "กรุงเทพมหานคร",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-12"
  },
  {
    id: 7,
    name: "นพดล ศรีสุข",
    email: "nopadon@gmail.com",
    phone: "084-555-1122",
    type: "การไฟฟ้า",
    area: "สมุทรสาคร",
    status: "ตักเตือน",
    verify: "รอการตรวจสอบ",
    date: "2026-02-28"
  },
  {
    id: 8,
    name: "พงศกร อินทร์แก้ว",
    email: "pong.tech@gmail.com",
    phone: "090-112-7788",
    type: "แอร์",
    area: "นนทบุรี",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-02"
  },
  {
    id: 9,
    name: "วีระชัย ใจกล้า",
    email: "weera@gmail.com",
    phone: "095-444-8899",
    type: "ประปา",
    area: "กรุงเทพมหานคร",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-08"
  },
  {
    id: 10,
    name: "อดิศักดิ์ มั่นคง",
    email: "adisak@gmail.com",
    phone: "083-222-9988",
    type: "ทาสี",
    area: "สมุทรปราการ",
    status: "ตักเตือน",
    verify: "ไม่ผ่าน",
    date: "2026-02-18"
  },
  {
    id: 11,
    name: "จักรพันธ์ พูลสุข",
    email: "jakpan@gmail.com",
    phone: "089-555-2233",
    type: "การไฟฟ้า",
    area: "กรุงเทพมหานคร",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-06"
  },
  {
    id: 12,
    name: "สุรชัย คงดี",
    email: "sura@gmail.com",
    phone: "081-999-2233",
    type: "แอร์",
    area: "นนทบุรี",
    status: "ปกติ",
    verify: "รอการตรวจสอบ",
    date: "2026-03-09"
  },
  {
    id: 13,
    name: "ธีรภัทร์ แก้วคำ",
    email: "teerapat@gmail.com",
    phone: "094-111-6677",
    type: "ประปา",
    area: "ปทุมธานี",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-11"
  },
  {
    id: 14,
    name: "วรพล ศรีทอง",
    email: "worapol@gmail.com",
    phone: "087-777-3344",
    type: "ทาสี",
    area: "กรุงเทพมหานคร",
    status: "แบนถาวร",
    verify: "ไม่ผ่าน",
    date: "2026-01-20"
  },
  {
    id: 15,
    name: "ณัฐพล สายชล",
    email: "natthapon@gmail.com",
    phone: "085-666-4455",
    type: "การไฟฟ้า",
    area: "สมุทรปราการ",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-13"
  },
  {
    id: 16,
    name: "ศุภชัย บุญมี",
    email: "supachai@gmail.com",
    phone: "092-444-1122",
    type: "แอร์",
    area: "นนทบุรี",
    status: "ตักเตือน",
    verify: "รอการตรวจสอบ",
    date: "2026-02-25"
  },
  {
    id: 17,
    name: "ก้องภพ รัตน์ทอง",
    email: "kongpop@gmail.com",
    phone: "096-222-7788",
    type: "ประปา",
    area: "กรุงเทพมหานคร",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-14"
  },
  {
    id: 18,
    name: "ปรีชา วงศ์ดี",
    email: "precha@gmail.com",
    phone: "098-111-5566",
    type: "ทาสี",
    area: "สมุทรสาคร",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-07"
  },
  {
    id: 19,
    name: "เอกชัย ศรีสม",
    email: "ekachai@gmail.com",
    phone: "089-888-3344",
    type: "การไฟฟ้า",
    area: "กรุงเทพมหานคร",
    status: "ตักเตือน",
    verify: "ไม่ผ่าน",
    date: "2026-02-10"
  },
  {
    id: 20,
    name: "พิชัย ชัยชนะ",
    email: "pichai@gmail.com",
    phone: "082-999-6677",
    type: "แอร์",
    area: "นนทบุรี",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-15"
  },
  {
    id: 21,
    name: "อานนท์ ใจบุญ",
    email: "anon@gmail.com",
    phone: "081-333-8899",
    type: "ประปา",
    area: "ปทุมธานี",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-16"
  },
  {
    id: 22,
    name: "ธวัชชัย คำดี",
    email: "thawat@gmail.com",
    phone: "086-111-2233",
    type: "ทาสี",
    area: "กรุงเทพมหานคร",
    status: "ตักเตือน",
    verify: "รอการตรวจสอบ",
    date: "2026-02-22"
  },
  {
    id: 23,
    name: "วิทยา สุขใจ",
    email: "witthaya@gmail.com",
    phone: "093-444-5566",
    type: "การไฟฟ้า",
    area: "สมุทรปราการ",
    status: "ปกติ",
    verify: "ผ่านการตรวจสอบ",
    date: "2026-03-17"
  },
  {
    id: 24,
    name: "สันติ ภักดี",
    email: "santi@gmail.com",
    phone: "095-222-3344",
    type: "แอร์",
    area: "นนทบุรี",
    status: "แบนถาวร",
    verify: "ไม่ผ่าน",
    date: "2026-01-05"
  }
]

export type TechnicianReport = {
  date: string
  type: string
  reason: string
  level: string
  admin: string
}

export const technicianReports: TechnicianReport[] = [
  {
    date: "2026-02-12",
    type: "พฤติกรรมไม่เหมาะสม",
    reason: "พูดจาไม่สุภาพกับลูกค้า",
    level: "ตักเตือน",
    admin: "Admin A"
  },
  {
    date: "2026-01-28",
    type: "งานล่าช้า",
    reason: "ไม่มาตามนัดและแจ้งล่าช้า",
    level: "ตักเตือน",
    admin: "Admin B"
  },
  {
    date: "2025-12-15",
    type: "คุณภาพงานต่ำ",
    reason: "งานไม่เรียบร้อย ต้องแก้ไขหลายครั้ง",
    level: "ตักเตือน",
    admin: "Admin A"
  },
  {
    date: "2025-11-30",
    type: "ยกเลิกงานกะทันหัน",
    reason: "ยกเลิกงานก่อนเริ่มงานโดยไม่มีเหตุผล",
    level: "ตักเตือน",
    admin: "Admin C"
  },
  {
    date: "2025-10-10",
    type: "ฉ้อโกง",
    reason: "เรียกเก็บเงินเกินจริงจากลูกค้า",
    level: "แบนถาวร",
    admin: "Super Admin"
  }
]
