import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/button/tertiary_button.dart';
import 'package:changsure/core/theme.dart';

import 'package:changsure/models/services/service.dart';
import 'package:changsure/models/services/service_detail_ui.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../homePage/service_card.dart';
import '../service/system_choose.dart';
import '../service/customer_choose.dart';

class ServiceDetail extends StatelessWidget {
  final int id;
  final ServiceDetailUI data;

  /// ถ้าคุณดึง related services จาก API ให้ส่งเข้ามาแทน []
  final List<ServiceModel> related;

  const ServiceDetail({
    super.key,
    required this.id,
    required this.data,
    this.related = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [_buildContent(context)]),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // -----------------------------
  // UI หลัก
  // -----------------------------
  Widget _buildContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        _buildHeaderImage(context),
        _buildPrice(),
        _divider(),
        _buildDescription(),
        _divider(),
        _buildConditions(),
        _divider(),
        _buildRelatedServicesSection(),
      ],
    );
  }

  // -----------------------------
  // ภาพ Header
  // -----------------------------
  Widget _buildHeaderImage(BuildContext context) {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: data.image,
          width: double.infinity,
          height: 330,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(height: 330, color: Colors.grey[300]),
          errorWidget: (_, __, ___) => Image.asset(
            "assets/image/clean3.png",
            height: 330,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        // ปุ่ม back + share
        Positioned(
          top: 30,
          left: 8,
          right: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  },
              ),
              const Icon(Icons.share, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }

  // -----------------------------
  // ราคา + ชื่อบริการ
  // -----------------------------
  Widget _buildPrice() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "฿",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBorderHover,
                ),
              ),
              Text(
                data.price,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBorderHover,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                "/ (เริ่มต้น)",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.colorTertiaryText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            data.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            data.subDetails,
            style: const TextStyle(fontSize: 12, color: Color(0xFF002C8C)),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // รายละเอียดบริการ
  // -----------------------------
  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "รายละเอียด",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),

          const SizedBox(height: 6),

          MarkdownBody(
            data: data.description,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 14,
                color: AppColors.colorTertiaryText,
              ),
              listBullet: const TextStyle(
                fontSize: 16,
                color: AppColors.colorTertiaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // เงื่อนไขเพิ่มเติม
  // -----------------------------
  Widget _buildConditions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "เงื่อนไขเพิ่มเติม",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          MarkdownBody(
            data: data.conditions,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 14,
                color: AppColors.colorTertiaryText,
              ),
              listBullet: const TextStyle(
                fontSize: 16,
                color: AppColors.colorTertiaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // บริการแนะนำ
  // -----------------------------
  Widget _buildRelatedServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            "บริการแนะนำ",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: related.isEmpty
              ? const Center(child: Text("ไม่มีบริการแนะนำ"))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemCount: related.length,
                  itemBuilder: (_, i) {
                    return SizedBox(
                      width: 160,
                      child: ServiceCard(data: related[i]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // -----------------------------
  // เส้นคั่นพื้นหลังเทา
  // -----------------------------
  Widget _divider() {
    return Container(height: 24, color: AppColors.primaryBGHover);
  }

  // -----------------------------
  // ปุ่มจองคิว
  // -----------------------------
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: PrimaryButton(
        text: "จองคิว",
        onPressed: () => _openBookingBottomSheet(context),
      ),
    );
  }

  // -----------------------------
  // Bottom Sheet เลือกช่าง
  // -----------------------------
  void _openBookingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildBookingSheet(context),
    );
  }

  Widget _buildBookingSheet(BuildContext context) {
    int selectedIndex = -1;
    final options = ["ระบบเลือกช่างให้อัตโนมัติ", "เลือกช่างด้วยตนเอง"];

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.50,
            maxChildSize: 0.50,
            minChildSize: 0.35,
            builder: (context, scrollController) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "เลือกวิธีการจองช่าง",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "คุณต้องการเลือกช่างแบบไหน?",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.colorTertiaryText,
                          ),
                        ),
                        const SizedBox(height: 24),

                        ...List.generate(options.length, (index) {
                          final isSelected = selectedIndex == index;

                          return GestureDetector(
                            onTap: () => setState(() => selectedIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryBGHover
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : const Color(0xFFD6D6D6),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    options[index],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF0F53BA),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Radio<int>(
                                    value: index,
                                    groupValue: selectedIndex,
                                    onChanged: (v) =>
                                        setState(() => selectedIndex = v!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TertiaryButton(
                                text: "ยกเลิก",
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                text: "ยืนยัน",
                                onPressed: selectedIndex != -1
                                    ? () {
                                        Navigator.pop(context);
                                        if (selectedIndex == 0) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SystemChoose(
                                                serviceName: data.name,
                                                category: data.category,
                                              ),
                                            ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CustomerChoose(
                                                serviceName: data.name,
                                                category: data.category,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
