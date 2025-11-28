import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme.dart';
import '../../../../models/badges/badge.dart';

const String minioBaseUrl =
    "http://cp25ssa1.sit.kmutt.ac.th:9011/changsure-dev";

class TechnicianBadge extends StatelessWidget {
  final List<BadgeResponse> badges;

  const TechnicianBadge({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 0, left: 4, top: 24),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/badge.svg',
                width: 14,
                height: 14,
                color: Colors.black,
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

        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: badges.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "ยังไม่มีป้ายสัญลักษณ์",
                    style: TextStyle(fontSize: 13, color: Color(0xFF9B9B9B)),
                  ),
                )
              : SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: badges.length,
                    separatorBuilder: (context, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final badge = badges[index];

                      final imageUrl = badge.iconUrl.isNotEmpty
                          ? "$minioBaseUrl/${badge.iconUrl}"
                          : "assets/icons/default_badge.png";

                      final isSvg = imageUrl.toLowerCase().endsWith(".svg");

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade100,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: imageUrl.startsWith("http")
                                  ? (isSvg
                                        ? SvgPicture.network(
                                            imageUrl,
                                            fit: BoxFit.contain,
                                            height: 70,
                                            width: 70,
                                            placeholderBuilder: (context) =>
                                                const Center(
                                                  child: SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ),
                                            // ถ้าโหลดไม่สำเร็จให้ fallback เป็น icon error
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  debugPrint(
                                                    "❌ SVG load error: $error",
                                                  );
                                                  return const Icon(
                                                    Icons.error,
                                                    color: Colors.redAccent,
                                                  );
                                                },
                                          )
                                        : Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.error,
                                                      color: Colors.redAccent,
                                                    ),
                                          ))
                                  : Image.asset(imageUrl, fit: BoxFit.contain),
                            ),
                          ),
                          const SizedBox(height: 6),
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
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
