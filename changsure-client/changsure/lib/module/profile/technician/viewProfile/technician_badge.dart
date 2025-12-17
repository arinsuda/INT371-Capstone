import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme.dart';
import '../../../../state/user_provider.dart';

class TechnicianBadge extends ConsumerWidget {
  const TechnicianBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final badges = user?.technicianProfile?.badges ?? [];

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------- หัวข้อ Section ----------
        Padding(
          padding: const EdgeInsets.only(bottom: 0, left: 4, top: 24),
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/badge.svg',
                    width: 14,
                    height: 14,
                    color: Colors.black,
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Text(
                'ป้ายสัญลักษณ์ของช่าง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        // ---------- ป้าย Badge ----------
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            // ใช้ crossAxisAlignment start เพื่อให้ text ยาวๆ ไม่ดัน layout เละ
            crossAxisAlignment: CrossAxisAlignment.start,
            children: badges.map((badge) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: Center(
                          child: Image.network(
                            badge.iconUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                            // ใส่ errorBuilder เผื่อรูปโหลดไม่ได้
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              );
                            },
                            // ใส่ loadingBuilder เพื่อความสวยงามตอนโหลด
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          badge.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
