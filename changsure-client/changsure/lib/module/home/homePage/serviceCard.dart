import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../mockDB/serviceCategories.dart';

class ServiceCard extends StatelessWidget {
  final SubServiceDetail data;

  const ServiceCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: SizedBox(
        height: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ภาพด้านบน
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.asset(
                data.image,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),

            // เนื้อหา
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อ
                    Text(
                      data.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const Spacer(),

                    // ราคา
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
                            text: "฿${data.price}",
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
}
