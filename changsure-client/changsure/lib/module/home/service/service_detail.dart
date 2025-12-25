import 'package:changsure/module/home/service/serviceDetails/service_image_carousel.dart';
import 'package:changsure/module/home/service/system_choose.dart';
import 'package:changsure/state/master_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/button/tertiary_button.dart';
import '../../../core/theme.dart';
import '../../../data/models/master_data_models.dart';
import '../homePage/service_card.dart';
import 'customer_choose.dart';

class ServiceDetail extends StatefulWidget {
  final int id;
  final ServiceModel data;
  final int? provinceId;

  const ServiceDetail({
    super.key,
    required this.id,
    required this.data,
    required this.provinceId,
  });

  @override
  State<ServiceDetail> createState() => _ServiceDetailState();
}

class _ServiceDetailState extends State<ServiceDetail> {
  late Future<List<ServiceModel>> _relatedFuture;

  @override
  void initState() {
    super.initState();

    _relatedFuture = MasterDataService().getServicesByCategory(
      widget.data.categoryId,
    );
  }

  Widget _priceTag({
    required String label,
    required int value,
    required int? current,
    required Function(int) onTap,
  }) {
    final isSelected = current == value;

    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? AppColors.primaryBGHover
              : const Color(0xFFF2F2F2),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(widget.provinceId);

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
                    child: widget.data.imageUrls.isNotEmpty
                        ? ServiceImageCarousel(imageUrls: widget.data.imageUrls)
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
                          "${widget.data.defaultPrice.min}",
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
                      widget.data.serName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),

                    SizedBox(height: 2),

                    if (widget.data.serDescription != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.data.serDescription!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              _sectionDivider(),

              _markdownSection(
                title: "รายละเอียด",
                data: widget.data.serDetails,
              ),

              _sectionDivider(),

              _markdownSection(
                title: "เงื่อนไขเพิ่มเติม",
                data: widget.data.additionalTerms,
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
                  height: 220,
                  child: FutureBuilder<List<ServiceModel>>(
                    future: _relatedFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Center(child: Text('โหลดบริการไม่สำเร็จ'));
                      }

                      final services = (snapshot.data ?? [])
                          .where(
                            (s) => s.id != widget.data.id,
                          ) // ❗ ตัดตัวเองออก
                          .toList();

                      if (services.isEmpty) {
                        return const Center(child: Text("ไม่มีบริการแนะนำ"));
                      }

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 0, right: 18),
                        itemCount: services.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          final service = services[index];

                          return SizedBox(
                            width: 160,
                            child: ServiceCard(
                              data: service,
                              provinceId: widget.provinceId,
                            ),
                          );
                        },
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
            int? selectedMaxPrice;
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
                              bool canConfirm() {
                                if (selectedIndex == -1) return false;
                                if (selectedIndex == 0 &&
                                    selectedMaxPrice == null)
                                  return false;
                                return true;
                              }

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

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedIndex = index;
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.primaryBGHover
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.secondary
                                                      : const Color(0xFFD6D6D6),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    options[index],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF0F53BA),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Radio<int>(
                                                    value: index,
                                                    groupValue: selectedIndex,
                                                    onChanged: (val) {
                                                      setState(() {
                                                        selectedIndex = val!;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          if (isSelected && index == 0) ...[
                                            const SizedBox(height: 4),
                                            const Text(
                                              "  กรุณาเลือกเรทราคาที่ท่านต้องการ",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _priceTag(
                                                  label: "ไม่เกิน ฿1,000",
                                                  value: 1000,
                                                  current: selectedMaxPrice,
                                                  onTap: (v) {
                                                    setState(
                                                      () =>
                                                          selectedMaxPrice = v,
                                                    );
                                                  },
                                                ),
                                                _priceTag(
                                                  label: "ไม่เกิน ฿3,000",
                                                  value: 3000,
                                                  current: selectedMaxPrice,
                                                  onTap: (v) {
                                                    setState(
                                                      () =>
                                                          selectedMaxPrice = v,
                                                    );
                                                  },
                                                ),
                                                _priceTag(
                                                  label: "ไม่เกิน ฿5,000",
                                                  value: 5000,
                                                  current: selectedMaxPrice,
                                                  onTap: (v) {
                                                    setState(
                                                      () =>
                                                          selectedMaxPrice = v,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                        ],
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
                                            onPressed: canConfirm()
                                                ? () {
                                                    Navigator.pop(context);

                                                    if (selectedIndex == 0) {
                                                      Navigator.push(
                                                        rootContext,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              SystemChoose(
                                                                serviceName:
                                                                    widget
                                                                        .data
                                                                        .serName,
                                                                category: widget
                                                                    .data
                                                                    .categoryId,
                                                                maxPrice:
                                                                    selectedMaxPrice ?? 5000,
                                                                serviceId:
                                                                    widget
                                                                        .data
                                                                        .id,
                                                                provinceId: widget
                                                                    .provinceId,
                                                              ),
                                                        ),
                                                      );
                                                    } else {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CustomerChoose(
                                                                serviceName:
                                                                    widget
                                                                        .data
                                                                        .serName,
                                                                category: widget
                                                                    .data
                                                                    .categoryId,
                                                                serviceId:
                                                                    widget
                                                                        .data
                                                                        .id,
                                                                provinceId: widget
                                                                    .provinceId,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                : null,
                                            padding: const EdgeInsets.symmetric(
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
