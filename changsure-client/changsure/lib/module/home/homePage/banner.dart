import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../mockDB/province.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  String selectedProvince = "กรุงเทพมหานคร";

  void _openProvinceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "เลือกจังหวัดที่ต้องการรับบริการ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            ...mockProvinces.map(
                  (p) => ListTile(
                title: Text(p),
                onTap: () {
                  setState(() => selectedProvince = p);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return
      SizedBox(
        height: 320, // ความสูงรวม Banner + Search bar
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner + gradient
            Container(
              height: 270,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/image/banner.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              height: 270,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFB7CFFF).withOpacity(0.1),
                    AppColors.primary.withOpacity(0.1),
                    const Color(0xFF001F9F).withOpacity(0.2),
                    const Color(0xFF020927).withOpacity(0.5),
                  ],
                ),
              ),
            ),

            // ปุ่มจังหวัด + notifications
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _openProvinceSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFF3071C7)),
                          const SizedBox(width: 6),
                          Text(
                            selectedProvince,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF3071C7), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF3071C7), size: 16),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Search bar ลอยทับ Banner
            Positioned(
              top: 240, // ทับเล็กน้อยบน Banner
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.colorStroke),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("ค้นหา...", style: TextStyle(color: Colors.grey)),
                    Icon(Icons.search, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }
}