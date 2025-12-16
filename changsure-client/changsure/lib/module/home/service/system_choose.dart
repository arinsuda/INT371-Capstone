import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/header.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/button/secondary_button.dart';
import '../../../core/theme.dart';
import '../../../mockDB/technician.dart';
import '../../profile/technician/view_profile_tab.dart';

class SystemChoose extends StatelessWidget {
  final String serviceName;
  final String category;

  const SystemChoose({
    super.key,
    required this.serviceName,
    required this.category,
  });

  // ================= TAG =================

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
    final map = {
      "ทาสี": (Color(0xFFEB2F96), Color(0xFFFFF0F6), Color(0xFFFFADD2)),
      "การประปา": (Color(0xFF36CFC9), Color(0xFFE6FFFB), Color(0xFF87E8DE)),
      "การไฟฟ้า": (Color(0xFFFAAD14), Color(0xFFFFFBE6), Color(0xFFFFE58F)),
      "เครื่องใช้ไฟฟ้า": (Color(0xFF722ED1), Color(0xFFF9F0FF), Color(0xFFD3ADF7)),
    };

    final colors = map[name] ??
        (Colors.grey, Colors.grey.shade100, Colors.grey.shade400);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.$3),
      ),
      child: Text(
        name,
        style: TextStyle(color: colors.$1, fontSize: 12),
      ),
    );
  }

  // ================= MAIN =================

  @override
  Widget build(BuildContext context) {
    // filter technician
    final technicians =
    mockTechnicians.where((t) => t.category == category).toList();

    final Technician? tech =
    technicians.isEmpty ? null : technicians[Random().nextInt(technicians.length)];

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

            // ===== SERVICE NAME =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(fontSize: 18, color: Colors.black),
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

            const SizedBox(height: 16),

            // ===== NO TECH =====
            if (tech == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    "ยังไม่มีช่างในหมวดหมู่นี้",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              )

            // ===== TECH CARD =====
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    _TechnicianCard(
                      tech: tech,
                      buildTag: _buildTag,
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildCategoryTag(tech.category),
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

// ================= CARD =================

class _TechnicianCard extends StatelessWidget {
  final Technician tech;
  final Widget Function(String, String) buildTag;

  const _TechnicianCard({
    required this.tech,
    required this.buildTag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBG,
        border: Border.all(color: AppColors.colorStroke),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 40, backgroundImage: AssetImage(tech.avatar)),
          const SizedBox(height: 8),
          Text(
            "${tech.firstName} ${tech.lastName}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: tech.tags
                .map((t) => buildTag(t["icon"]!, t["text"]!))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: "ดูโปรไฟล์",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ViewProfilePage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: "จองช่าง",
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
