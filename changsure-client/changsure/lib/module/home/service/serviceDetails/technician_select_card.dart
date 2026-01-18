import 'package:changsure/module/home/booking/booking_page.dart';
import 'package:flutter/material.dart';
import '../../../../core/button/primary_button.dart';
import '../../../../core/button/secondary_button.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/master_data_models.dart';
import '../../../profile/technician/view_profile_tab.dart';

class TechnicianCardCTM extends StatelessWidget {
  final Technician technician;
  final ServiceModel data;

  const TechnicianCardCTM({
    super.key,
    required this.technician,
    required this.data,
  });

  Widget _buildTag(String iconUrl, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            iconUrl,
            width: 14,
            height: 14,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 14),
          ),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10)),
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
      "ประปา": {
        "text": const Color(0xFF36CFC9),
        "background": const Color(0xFFE6FFFB),
        "border": const Color(0xFF87E8DE),
      },
      "ไฟฟ้า": {
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

  String _getDisplayCategoryName(String categoryName) {
    final displayMap = {
      "งานทาสี": "ทาสี",
      "งานประปา": "ประปา",
      "งานไฟฟ้า": "ไฟฟ้า",
      "งานเครื่องใช้ไฟฟ้า": "เครื่องใช้ไฟฟ้า",
    };

    return displayMap[categoryName] ?? categoryName;
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
                        backgroundImage:
                            tech.avatarUrl != null && tech.avatarUrl!.isNotEmpty
                            ? NetworkImage(tech.avatarUrl!)
                            : null,
                        child: tech.avatarUrl == null
                            ? Icon(Icons.person, size: 40)
                            : null,
                      ),

                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.colorTertiaryText,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "${tech.distanceKm.toStringAsFixed(1)} km",
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
                            Text(
                              "คุณ ",
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              tech.firstname,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              tech.lastname,
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
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  tech.priceMax > tech.priceMin
                                      ? "฿${tech.priceMin} - ${tech.priceMax}"
                                      : "฿${tech.priceMin}",
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
                              tech.ratingAvg?.toString() ?? "0",
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
                              "จำนวนงานที่รับ: ",
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
                          children: tech.badges
                              .where((b) => b.isActive)
                              .map((b) => _buildTag(b.iconUrl, b.name))
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
                            builder: (context) => (BookingPage(data: data, technician: technician)),
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
        Positioned(
          top: 16,
          right: 16,
          child: _buildCategoryTag(_getDisplayCategoryName(tech.categoryName)),
        ),
      ],
    );
  }
}
