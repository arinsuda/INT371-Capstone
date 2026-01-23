
// ข้อมูลจำลองของช่าง
class Technician {
  final String firstName;
  final String lastName;
  final String avatar;
  final double distance; // km
  final double rating; // คะแนน
  final int jobsCompleted;
  final int price; // ราคาเริ่มต้น
  final List<Map<String, String>> tags; // tag: icon + text
  final String category; // หมวดหมู่
  final List<String> categoryTags; // เช่น Top Service, Recommend

  Technician({
    required this.firstName,
    required this.lastName,
    required this.avatar,
    required this.distance,
    required this.rating,
    required this.jobsCompleted,
    required this.price,
    required this.tags,
    required this.category,
    required this.categoryTags,
  });
}

// mock list ของช่าง
final List<Technician> mockTechnicians = [
  Technician(
    firstName: "สมชาย",
    lastName: "รักชาติ",
    avatar: "assets/image/Technician.png",
    distance: 2.0,
    rating: 4.9,
    jobsCompleted: 34,
    price: 1000,
    tags: [
      {"icon": "assets/icons/top_service.png", "text": "Top Service"},
      {"icon": "assets/icons/changSure_rec.png", "text": "ChangSure Recommend"},
    ],
    category: "ทาสีภายในอาคาร",
    categoryTags: ["Top Service", "ChangSure Recommend"],
  ),
  Technician(
    firstName: "สมปอง",
    lastName: "ดีจริง",
    avatar: "assets/image/Technician.png",
    distance: 3.5,
    rating: 4.7,
    jobsCompleted: 28,
    price: 1200,
    tags: [
      {"icon": "assets/icons/high_rating.png", "text": "High-Rating Technician"},
      {"icon": "assets/icons/fast_response.png", "text": "Fast Response Technician"},
    ],
    category: "ทาสี",
    categoryTags: ["High-Rating Technician", "Fast Response Technician"],
  ),
  Technician(
    firstName: "สมชาย",
    lastName: "เก่งจริง",
    avatar: "assets/image/Technician.png",
    distance: 1.2,
    rating: 5.0,
    jobsCompleted: 50,
    price: 1500,
    tags: [
      {"icon": "assets/icons/top_service.png", "text": "Top Service"},
      {"icon": "assets/icons/high_rating.png", "text": "High-Rating Technician"},
      {"icon": "assets/icons/fast_response.png", "text": "Fast Response Technician"},
    ],
    category: "การประปา",
    categoryTags: ["Top Service", "High-Rating Technician", "Fast Response Technician"],
  ),
  Technician(
    firstName: "สมชาย",
    lastName: "สุดยอด",
    avatar: "assets/image/Technician.png",
    distance: 5.0,
    rating: 4.5,
    jobsCompleted: 20,
    price: 900,
    tags: [
      {"icon": "assets/icons/changSure_rec.png", "text": "ChangSure Recommend"},
    ],
    category: "ทาสี",
    categoryTags: ["ChangSure Recommend"],
  ),
];
