import 'package:changsure/models/services/service.dart';
import 'package:changsure/models/services/service_detail_ui.dart';
import 'package:changsure/state/service_state.dart';
import 'package:changsure/module/home/service/system_choose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/button/tertiary_button.dart';
import '../../../core/theme.dart';
import '../homePage/service_card.dart';
import 'customer_choose.dart';

class ServiceDetail extends StatefulWidget {
  final int id;
  final ServiceDetailUI data;

  const ServiceDetail({super.key, required this.id, required this.data});

  @override
  State<ServiceDetail> createState() => _ServiceDetailState();
}

class _ServiceDetailState extends State<ServiceDetail> {
  List<ServiceModel> related = [];

  @override
  void initState() {
    super.initState();

    // โหลดบริการแนะนำ (service ที่ category เดียวกัน)
    Future.microtask(() async {
      final serviceState = context.read<ServiceState>();

      await serviceState.loadServices(
        categoryId: widget.data.id, // หรือ categoryId จริงจาก service
        isActive: true,
      );

      setState(() {
        related = (serviceState.services ?? [])
            .where((s) => s.id != widget.id)
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    String priceDisplay = data.price;

    if (priceDisplay.contains("null")) {
      priceDisplay = priceDisplay
          .replaceAll("null", "")
          .replaceAll("-", "")
          .trim();
    }

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(top: 0, bottom: 16),
            children: [
              // -------------------- รูปด้านบน --------------------
              Stack(
                children: [
                  Container(
                    height: 370,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: data.image.startsWith("http")
                            ? NetworkImage(data.image)
                            : AssetImage(data.image) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 8,
                    right: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Icon(Icons.share, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // -------------------- ราคา + ชื่อ --------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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
                          priceDisplay,
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
                    const SizedBox(height: 2),

                    Text(
                      data.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      data.subDetails,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF002C8C),
                      ),
                    ),
                  ],
                ),
              ),

              Container(height: 24, color: AppColors.primaryBGHover),

              // -------------------- รายละเอียด --------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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
                    const SizedBox(height: 4),
                    MarkdownBody(
                      data: data.description,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 14,
                          color: AppColors.colorTertiaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(height: 24, color: AppColors.primaryBGHover),

              // -------------------- เงื่อนไขเพิ่มเติม --------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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
                    const SizedBox(height: 4),
                    MarkdownBody(
                      data: data.conditions,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 14,
                          color: AppColors.colorTertiaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(height: 24, color: AppColors.primaryBGHover),

              // -------------------- บริการแนะนำ --------------------
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: 8,
                ),
                child: const Text(
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
                        padding: const EdgeInsets.only(left: 18, right: 18),
                        itemCount: related.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 160,
                            child: ServiceCard(data: related[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),

      // -------------------- ปุ่มจองคิว --------------------
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          right: 16,
          left: 16,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
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
          onPressed: () {
            // --- modal UI เดิมทั้งหมด ---
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) {
                return _buildBookingSheet(context, data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingSheet(BuildContext context, ServiceDetailUI data) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.53,
            maxChildSize: 0.53,
            minChildSize: 0.3,
            builder: (context, scrollController) {
              int selectedIndex = -1;
              final options = [
                "ระบบเลือกช่างให้อัตโนมัติ",
                "เลือกช่างด้วยตนเอง",
              ];

              return StatefulBuilder(
                builder: (context, setState) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
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
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
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
                            onTap: () {
                              setState(() => selectedIndex = index);
                            },
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
                                    onChanged: (val) {
                                      setState(() => selectedIndex = val!);
                                    },
                                    fillColor:
                                        MaterialStateProperty.resolveWith(
                                          (states) =>
                                              states.contains(
                                                MaterialState.selected,
                                              )
                                              ? const Color(0xFF0F53BA)
                                              : const Color(0xFFD6D6D6),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

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
                                onPressed: () {
                                  if (selectedIndex == -1) return;

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
                                },
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
