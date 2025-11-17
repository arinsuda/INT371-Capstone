import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import 'technicianBadge.dart';
import 'service.dart';

class ViewProfileContent extends StatelessWidget {
  const ViewProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      children: [
        // Avatar + Info
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
        // ... ใส่ content เดิมที่เหลือเหมือนโค้ดของคุณ
        TechnicianBadge(),
        const SizedBox(height: 8),
        // About
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "เกี่ยวกับ",
              style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "ใช้เฉพาะวัสดุคุณภาพดีและปลอดกลิ่นแรง...",
              style: TextStyle(fontSize: 14, color: AppColors.colorTertiaryText),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ServiceTag(),
      ],
    );
  }
}
