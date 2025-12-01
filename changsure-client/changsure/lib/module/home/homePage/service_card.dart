import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/models/services/service.dart';
import 'package:changsure/models/services/service_detail_ui.dart';
import '../service/service_detail.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel data;

  const ServiceCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    /// รูปแรก ถ้าไม่มี → placeholder
    final imageUrl = (data.imageUrls.isNotEmpty)
        ? data.imageUrls.first
        : "https://via.placeholder.com/300x200?text=No+Image";

    final priceText = _buildPriceText(data);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        /// แปลง model → UI model
        final uiData = ServiceDetailUI.fromServiceModel(data);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetail(id: data.id, data: uiData),
          ),
        );
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -----------------------------
            /// รูปภาพ พร้อมแคช
            /// -----------------------------
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(height: 120, color: Colors.grey[200]),
                errorWidget: (_, __, ___) => Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 40),
                ),

                /// จำกัดขนาดแคช (เพิ่ม performance)
                memCacheWidth: 400,
                memCacheHeight: 400,
                maxWidthDiskCache: 400,
                maxHeightDiskCache: 400,
              ),
            ),

            /// -----------------------------
            /// ส่วนเนื้อหาด้านล่าง
            /// -----------------------------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ชื่อบริการ
                    Text(
                      data.serName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// หมวดหมู่ (ถ้ามี)
                    if (data.categoryName != null)
                      Text(
                        data.categoryName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.colorTertiaryText,
                        ),
                      ),

                    const Spacer(),

                    /// ราคาเริ่มต้น
                    if (priceText != null)
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(
                            context,
                          ).style.copyWith(fontSize: 12),
                          children: [
                            const TextSpan(
                              text: "เริ่มต้น ",
                              style: TextStyle(
                                color: AppColors.colorTertiaryText,
                              ),
                            ),
                            TextSpan(
                              text: priceText,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ------------------------------------------------
  /// ฟังก์ชันแสดงราคา รองรับ: fixed, range, null-safe
  /// ------------------------------------------------
  String? _buildPriceText(ServiceModel m) {
    final p = m.defaultPrice;
    if (p == null) return null;

    final type = p["type"];

    if (type == "fixed") {
      final value = p["value"];
      if (value == null) return null;
      return "฿$value";
    }

    if (type == "range") {
      final min = p["min"];
      final max = p["max"];

      if (min != null && max != null) return "฿$min - ฿$max";
      if (min != null) return "฿$min";
      if (max != null) return "฿$max";

      return null;
    }

    return null;
  }
}
