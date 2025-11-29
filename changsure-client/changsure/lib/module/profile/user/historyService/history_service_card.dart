import 'package:changsure/core/button/primary_button.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../mockDB/history_service.dart'; // ไฟล์ที่คุณเก็บ model ไว้

class ServiceCard extends StatelessWidget {
  final HistoryService service;

  const ServiceCard({super.key, required this.service, });

  Color getStatusColor(String status) {
    switch (status) {
      case "เสร็จสิ้น":
        return AppColors.colorTertiaryText;
      case "กำลังดำเนินการ":
        return AppColors.primary;
      case "ยกเลิก":
        return Colors.red;
      default:
        return AppColors.colorTertiaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- SECTION 1 (รูป + รายละเอียดด้านขวา) ----------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // รูป
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  service.image,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 12),

              // ---------- ข้อความด้านขวา ----------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อบริการ + สถานะ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.serviceName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          service.status,
                          style: TextStyle(
                            fontSize: 14,
                            color: getStatusColor(service.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    Text(
                      "${service.price}฿",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "x${service.quantity}",
                          style: const TextStyle(
                            color: AppColors.colorTertiaryText,
                            fontSize: 12,
                          ),
                        ),

                        Text(
                          "${service.price}฿",
                          style: const TextStyle(
                            color: AppColors.colorTertiaryText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          "ทั้งหมด:",
                          style: TextStyle(
                            color: AppColors.colorTertiaryText,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "${service.price * service.quantity}฿",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ---------- SECTION 2 ปุ่มล่าง ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ปุ่มทั้งสองมีความกว้างเท่ากัน
              SizedBox(
                width: 120, // กำหนดความกว้างที่ต้องการ
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: AppColors.colorStroke),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "รับบริการอีกครั้ง",
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                width: 120, // เท่ากับปุ่มแรก
                child: PrimaryButton(
                  text: "ให้คะแนน",
                  onPressed: () {},
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  borderRadius: 16,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Divider(height: 1, color: AppColors.colorStroke),
          ),
        ],
      ),
    );
  }
}
