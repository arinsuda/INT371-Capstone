import 'package:changsure/module/profile/viewProfile/service.dart';
import 'package:changsure/module/profile/viewProfile/technicianBadge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../state/bottomBarState.dart';

class ViewProfile extends StatefulWidget {
  const ViewProfile({super.key});

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          children: [
            // ---------- Header ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => {
                    Provider.of<BottomBarState>(
                      context,
                      listen: false,
                    ).closeSubPage(),
                  },
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "ดูโปรไฟล์ช่าง",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004AAD),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),

            // ---------- Avatar ----------
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/image/Technician.png'),
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
                  mainAxisSize: MainAxisSize.min, // ให้ Row กว้างเท่าข้อความ
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
                  mainAxisSize: MainAxisSize.min,
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
            TechnicianBadge(),

            const SizedBox(height: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "เกี่ยวกับ",
                  style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  "ใช้เฉพาะวัสดุคุณภาพดีและปลอดกลิ่นแรงเคยรับงานรีโนเวทบ้านและคอนโดขนาดเล็กถึงกลาง เน้นงานเนี๊ยบ สีเรียบเนียน และส่งมอบตรงเวลา ",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.colorTertiaryText,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ServiceTag()
          ],
        ),
      ),
    );
  }
}
