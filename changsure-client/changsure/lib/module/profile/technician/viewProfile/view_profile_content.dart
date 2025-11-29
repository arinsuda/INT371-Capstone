import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/theme.dart';
import 'activity_section.dart';
import 'technician_badge.dart';
import 'service.dart';

class ViewProfileContent extends StatelessWidget {
  const ViewProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        'assets/image/Technician.png',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFFE8E8E8),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.center, // กึ่งกลางแนวนอน
                children: [
                  // ชื่อ + icon verify
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // ให้ Row กว้างเท่าข้อความ
                    children: [
                      Text(
                        "คุณ สมชาย ใจดี",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Image.asset(
                        'assets/icons/verify.png',
                        width: 24,
                        height: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.email, size: 14, color: Color(0xFF9B9B9B)),
                      SizedBox(width: 4),
                      Text(
                        'somchai@gmail.com',
                        style: TextStyle(fontSize: 10, color: Color(0xFF545454)),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.phone, size: 14, color: Color(0xFF9B9B9B)),
                      SizedBox(width: 4),
                      Text(
                        '081-234-5678',
                        style: TextStyle(fontSize: 10, color: Color(0xFF545454)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/bag_work.svg',
                        width: 14,
                        height: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'จำนวนงานที่รับ: 34',
                        style: TextStyle(fontSize: 10, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TechnicianBadge(),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "เกี่ยวกับ",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "ใช้เฉพาะวัสดุคุณภาพดีและปลอดกลิ่นแรง...",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.colorTertiaryText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ServiceTag(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // SliverGrid สำหรับ ActivitySection
        const ActivitySection(),
      ],
    );
  }
}
