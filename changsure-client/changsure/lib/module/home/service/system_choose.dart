import 'package:changsure/core/header.dart';
import 'package:changsure/module/profile/technician/view_profile_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/button/secondary_button.dart';
import '../../../core/theme.dart';
import '../../../mockDB/services_categories.dart';
import '../../../state/bottom_bar_state.dart';
import '../../profile/technician/viewProfile/service.dart';

import 'dart:math';
import 'package:changsure/core/header.dart';
import 'package:changsure/module/profile/technician/view_profile_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/button/secondary_button.dart';
import '../../../core/theme.dart';
import '../../../mockDB/technician.dart';
import '../../../state/bottom_bar_state.dart';

class SystemChoose extends StatelessWidget {
  final String serviceName;
  final String category;

  const SystemChoose({
    super.key,
    required this.serviceName,
    required this.category,
  });

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

  Widget buildSingleTag(String name) {
    final Map<String, Map<String, Color>> colorMap = {
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

    final colors = colorMap[name]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors["background"],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors["border"]!, width: 1),
      ),
      child: Text(name, style: TextStyle(color: colors["text"], fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. filter ช่างตาม category
    final List<Technician> filteredTechnicians = mockTechnicians
        .where((tech) => tech.category == category)
        .toList();

    // 2. random ช่างคนเดียว
    final random = Random();
    Technician? chosenTechnician;
    if (filteredTechnicians.isNotEmpty) {
      chosenTechnician =
          filteredTechnicians[random.nextInt(filteredTechnicians.length)];
    }

    if (chosenTechnician == null) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            children: [
              Header(
                header: "ระบบเลือกช่างอัตโนมัติ",
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    final tech = chosenTechnician;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Header(
              header: "ระบบเลือกช่างอัตโนมัติ",
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),
                  const Text(
                    "เราจะแนะนำช่างที่เหมาะสมที่สุดตามงานของคุณ",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.colorTertiaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBG,
                      border: Border.all(color: AppColors.colorStroke),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
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
                        const SizedBox(height: 4),
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage(tech.avatar),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tech.firstName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              tech.lastName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.verified,
                              color: AppColors.primary,
                              size: 12,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "฿",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "${tech.price}",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rate_rounded,
                              color: Color(0xFFFFC53D),
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "${tech.rating}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "|",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.colorStroke,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "จำนวนงานที่รับ: ${tech.jobsCompleted}",
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.colorTertiaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: tech.tags
                              .map(
                                (tag) => _buildTag(tag["icon"]!, tag["text"]!),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: "ดูโปรไฟล์",
                                onPressed: () {
                                  Provider.of<BottomBarState>(
                                    context,
                                    listen: false,
                                  ).setSubPage(ViewProfilePage());
                                },
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                text: "จองช่าง",
                                onPressed: () {},
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
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
                    child: buildSingleTag(tech.category),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
