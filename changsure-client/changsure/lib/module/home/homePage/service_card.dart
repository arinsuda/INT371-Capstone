import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/master_data_models.dart';
import '../service/service_detail.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel data;
  final int? provinceId;

  const ServiceCard({super.key, required this.data, required this.provinceId});

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = data.available;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      // ถ้า available = false → ปิด onTap
      onTap: isAvailable
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: '/serviceDetail'),
                  builder: (_) => ServiceDetail(
                    id: data.id,
                    data: data,
                    provinceId: provinceId,
                    categoryId: data.categoryId,
                  ),
                ),
              );
            }
          : null,
      child: Opacity(
        // dim การ์ดที่ไม่มีช่าง
        opacity: isAvailable ? 1.0 : 0.5,
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          child: SizedBox(
            height: 210,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รูปภาพ
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: data.imageUrls.isNotEmpty
                          ? Image.network(
                              data.imageUrls.first,
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/image/no_image.png',
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/image/no_image.png',
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                    ),

                    // badge "ไม่มีช่าง" บนรูป
                    if (!isAvailable)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ไม่มีช่างในพื้นที่',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ข้อความ + ราคา
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.serName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),

                        // ราคา หรือ warning
                        if (isAvailable)
                          RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(
                                context,
                              ).style.copyWith(fontSize: 12),
                              children: [
                                const TextSpan(
                                  text: 'เริ่มต้น ',
                                  style: TextStyle(
                                    color: AppColors.colorTertiaryText,
                                  ),
                                ),
                                TextSpan(
                                  text: data.defaultPrice.displayText,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // warning text แดง
                          const Text(
                            'ยังไม่มีช่างรับบริการนี้\nในจังหวัดของคุณ',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
