import 'package:changsure/mockDB/servicesCategories.dart';

class Activity {
  final String serviceCategoryName; // แค่ชื่อ category
  final String description;
  final List<String> images;

  Activity({
    required this.serviceCategoryName,
    required this.description,
    required this.images,
  });
}

List<Activity> mockActivities = [
  Activity(
    serviceCategoryName: mockServiceCategories[0].name, // "ช่างทาสี"
    description:
        "งานทาสีภายในบ้านสองชั้น ขนาดพื้นที่ 180 ตารางเมตร ใช้สีเบอร์ 734 จาก TOA SuperShield ทนแดดทนฝน ทำความสะอาดพื้นผิวก่อนทา 2 ชั้น ใช้เวลาทำทั้งหมด 3 วัน ลูกค้าพึงพอใจและรีวิวให้ คะแนนเต็ม 5 ดาวเลยครับ ท่านใดสนใจ จองมาครับ 👍🏻",
    images: [
      "assets/image/clean1.png",
      "assets/image/clean2.png",
      "assets/image/clean3.png",
      "assets/image/clean4.png",
    ],
  ),
  Activity(
    serviceCategoryName: mockServiceCategories[1].name, // "ช่างประปา"
    description: "ติดตั้งอ่างล้างหน้าในห้องน้ำ",
    images: [
      "assets/image/clean2.png",
      "assets/image/clean2.png",
      "assets/image/clean2.png",
    ],
  ),
  Activity(
    serviceCategoryName: mockServiceCategories[2].name, // "ช่างไฟฟ้า"
    description: "เปลี่ยนสวิตช์ไฟและติดตั้งเบรกเกอร์ใหม่",
    images: ["assets/image/clean3.png", "assets/image/clean2.png"],
  ),
  Activity(
    serviceCategoryName: mockServiceCategories[3].name, // "ช่างไฟฟ้า"
    description: "เปลี่ยนสวิตช์ไฟและติดตั้งเบรกเกอร์ใหม่",
    images: ["assets/image/clean3.png"],
  ),
  Activity(
    serviceCategoryName: mockServiceCategories[3].name, // "ช่างไฟฟ้า"
    description: "เปลี่ยนสวิตช์ไฟและติดตั้งเบรกเกอร์ใหม่",
    images: ["assets/image/clean3.png"],
  ),
  Activity(
    serviceCategoryName: mockServiceCategories[3].name, // "ช่างไฟฟ้า"
    description: "เปลี่ยนสวิตช์ไฟและติดตั้งเบรกเกอร์ใหม่",
    images: ["assets/image/clean3.png"],
  ),
  Activity(
    serviceCategoryName: mockServiceCategories[3].name, // "ช่างไฟฟ้า"
    description: "เปลี่ยนสวิตช์ไฟและติดตั้งเบรกเกอร์ใหม่",
    images: ["assets/image/clean3.png"],
  ),
];
