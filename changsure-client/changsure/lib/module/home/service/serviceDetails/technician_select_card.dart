import 'package:changsure/module/home/booking/booking_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/button/primary_button.dart';
import '../../../../core/button/secondary_button.dart';
import '../../../../core/theme.dart';
import '../../../../mockDB/technician.dart';
import '../../../../state/bottom_nav_provider.dart';
import '../../../profile/technician/view_profile_tab.dart';

class TechnicianCardCTM extends StatelessWidget {
  final Technician technician;

  const TechnicianCardCTM({super.key, required this.technician});

  Widget _buildTag(String imagePath, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF9FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(imagePath, width: 16, height: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.primaryBorderHover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(String name) {
    final colorMap = {
      "ทาสี": {
        "text": const Color(0xFFEB2F96),
        "background": const Color(0xFFFFF0F6),
        "border": const Color(0xFFFFADD2),
      },
      "การประปา": {
        "text": const Color(0xFF36CFC9),
        "background": const Color(0xFFE6FFFB),
        "border": const Color(0xFF87E8DE),
      },
      "การไฟฟ้า": {
        "text": const Color(0xFFFAAD14),
        "background": const Color(0xFFFFFBE6),
        "border": const Color(0xFFFFE58F),
      },
      "เครื่องใช้ไฟฟ้า": {
        "text": const Color(0xFF722ED1),
        "background": const Color(0xFFF9F0FF),
        "border": const Color(0xFFD3ADF7),
      },
    };

    final color = colorMap[name] ?? colorMap["ทาสี"]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color["background"],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color["border"]!, width: 1),
      ),
      child: Text(name, style: TextStyle(color: color["text"], fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tech = technician;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryBG,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.colorStroke),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage(tech.avatar),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.colorTertiaryText,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "${tech.distance} km",
                            style: const TextStyle(
                              color: AppColors.colorTertiaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                tech.firstName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              tech.lastName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: AppColors.primary,
                              size: 14,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              "฿",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "${tech.price}",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.star_rate_rounded,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${tech.rating}",
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              " / 5",
                              style: TextStyle(
                                color: AppColors.colorTertiaryText,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "|",
                              style: TextStyle(
                                color: AppColors.colorStroke,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "จำนวนงานที่รับ: ${tech.jobsCompleted}",
                              style: const TextStyle(
                                color: AppColors.colorTertiaryText,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 2,
                          runSpacing: 6,
                          alignment: WrapAlignment.start,
                          children: tech.tags
                              .map(
                                (tag) => _buildTag(tag["icon"]!, tag["text"]!),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: "ดูโปรไฟล์",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ViewProfilePage(),
                          ),
                        );
                      },
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: "จองช่าง",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => (BookingPage()),
                          ),
                        );
                      },
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(top: 16, right: 16, child: _buildCategoryTag(tech.category)),
      ],
    );
  }
}
