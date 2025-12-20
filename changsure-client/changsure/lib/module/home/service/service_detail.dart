import 'package:changsure/module/home/service/serviceDetails/service_image_carousel.dart';
import 'package:changsure/module/home/service/system_choose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/button/tertiary_button.dart';
import '../../../core/theme.dart';
import '../../../data/models/master_data_models.dart';
import '../../../mockDB/service_categories.dart';
import '../homePage/service_card.dart';
import 'customer_choose.dart';

class ServiceDetail extends StatelessWidget {
  final int id;
  final ServiceModel data;

  const ServiceDetail({super.key, required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    // ดึงหมวดของบริการนี้
    final category = mockServiceCategories.firstWhere(
      (cat) =>
          cat.name == data.categoryId ||
          cat.subServices.any((s) => s.id == data.id),
      orElse: () => mockServiceCategories[0],
    );

    // รายการบริการแนะนำ = subServices ในหมวดเดียวกัน ยกเว้นตัวเอง
    final relatedServices = category.subServices
        .where((s) => s.id != data.id)
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(top: 0, bottom: 16),
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 370,
                    child: data.imageUrls.isNotEmpty
                        ? ServiceImageCarousel(imageUrls: data.imageUrls)
                        : Image.asset(
                            'assets/image/no_image.png',
                            fit: BoxFit.cover,
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

              SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "฿",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBorderHover,
                          ),
                        ),
                        Text(
                          "${data.defaultPrice.min}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBorderHover,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "/ (เริ่มต้น)",
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.colorTertiaryText,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 2),

                    Text(
                      data.serName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),

                    SizedBox(height: 2),

                    if (data.serDescription != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        data.serDescription!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              _sectionDivider(),

              _markdownSection(title: "รายละเอียด", data: data.serDetails),

              _sectionDivider(),

              _markdownSection(
                title: "เงื่อนไขเพิ่มเติม",
                data: data.additionalTerms,
              ),

              _sectionDivider(),

              Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  bottom: 8,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "บริการแนะนำ",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  left: 18,
                  right: 0,
                  top: 0,
                  bottom: 16,
                ),
                child: SizedBox(
                  height: 220, // สูงเท่ากับ ServiceCard
                  child: relatedServices.isEmpty
                      ? const Center(child: Text("ไม่มีบริการแนะนำ"))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 0, right: 18),
                          itemCount: relatedServices.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final subService = relatedServices[index];
                            return SizedBox(
                              width: 160, // กำหนดความกว้างการ์ด
                              child: ServiceCard(data: data),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ],
      ),

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
            final rootContext = context;
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) {
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
                          int selectedIndex =
                              -1; // เริ่มต้นเป็น -1 (ไม่ได้เลือก)

                          return StatefulBuilder(
                            builder: (context, setState) {
                              final options = [
                                "ระบบเลือกช่างให้อัตโนมัติ",
                                "เลือกช่างด้วยตนเอง",
                              ];

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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "เลือกวิธีการจองช่าง",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryText,
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
                                        onTap: () {
                                          setState(() {
                                            selectedIndex = index;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primaryBGHover
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.secondary
                                                  : Color(0xFFD6D6D6),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                options[index],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF0F53BA),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Radio<int>(
                                                value: index,
                                                groupValue: selectedIndex,
                                                fillColor:
                                                    MaterialStateProperty.resolveWith<
                                                      Color
                                                    >((states) {
                                                      if (states.contains(
                                                        MaterialState.selected,
                                                      )) {
                                                        return Color(
                                                          0xFF0F53BA,
                                                        );
                                                      }
                                                      return Color(0xFFD6D6D6);
                                                    }),
                                                onChanged: (val) {
                                                  setState(() {
                                                    selectedIndex = val!;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 16),

                                    Row(
                                      children: [
                                        // ปุ่มยกเลิก
                                        Expanded(
                                          child: TertiaryButton(
                                            text: "ยกเลิก",
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
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
                                                        rootContext,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              SystemChoose(
                                                                serviceName:
                                                                    data.serName,
                                                                category: data
                                                                    .categoryId,
                                                              ),
                                                        ),
                                                      );
                                                    } else if (selectedIndex ==
                                                        1) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CustomerChoose(
                                                                serviceName:
                                                                    data.serName,
                                                                category: data
                                                                    .categoryId,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                : null,
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
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
              },
            );
          },
          padding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

Widget _sectionDivider() {
  return Container(height: 24, color: AppColors.primaryBGHover);
}

Widget _markdownSection({required String title, required List<String> data}) {
  if (data.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        MarkdownBody(data: data.map((e) => "- $e").join('\n')),
      ],
    ),
  );
}
