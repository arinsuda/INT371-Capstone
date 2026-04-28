import 'package:changsure/module/home/service/serviceDetails/service_image_carousel.dart';
import 'package:changsure/module/home/service/system_choose.dart';
import 'package:changsure/state/master_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/button/tertiary_button.dart';
import '../../../core/theme.dart';
import '../../../data/models/master_data_models.dart';
import '../../../data/models/users/users_model.dart';
import '../homePage/service_card.dart';
import 'customer_choose.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/state/user_provider.dart';

class ServiceDetail extends ConsumerStatefulWidget {
  final int id;
  final ServiceModel data;
  final int? provinceId;
  final int categoryId;

  const ServiceDetail({
    super.key,
    required this.id,
    required this.data,
    required this.provinceId,
    required this.categoryId,
  });

  @override
  ConsumerState<ServiceDetail> createState() => _ServiceDetailState();
}

class _ServiceDetailState extends ConsumerState<ServiceDetail> {
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
    final user = ref.watch(userProvider);
    final isTechnician = user?.role == UserRole.technician;

    final detailAsync = ref.watch(
      serviceMenuDetailProvider(
        ServiceMenuDetailQuery(
          serviceId: widget.id,
          provinceId: widget.provinceId ?? 1,
        ),
      ),
    );

    final menuAsync = ref.watch(serviceMenuProvider(widget.provinceId ?? 1));

    return detailAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('โหลดข้อมูลไม่สำเร็จ: $e'))),
      data: (service) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 18),
                child: Icon(Icons.share, color: Colors.white),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(top: 0, bottom: 16),
            children: [
              SizedBox(
                height: 370,
                child: service.imageUrls.isNotEmpty
                    ? ServiceImageCarousel(imageUrls: service.imageUrls)
                    : Image.asset(
                        'assets/image/no_image.png',
                        fit: BoxFit.cover,
                      ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          service.defaultPrice.displayText,
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
                      service.serName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    if (service.serDescription != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.serDescription!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              _sectionDivider(),
              _markdownSection(title: "รายละเอียด", data: service.serDetails),
              _sectionDivider(),
              _markdownSection(
                title: "เงื่อนไขเพิ่มเติม",
                data: service.additionalTerms,
              ),
              _sectionDivider(),

              const Padding(
                padding: EdgeInsets.only(
                  top: 16,
                  bottom: 8,
                  left: 24,
                  right: 24,
                ),
                child: Text(
                  "บริการแนะนำ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
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
                  child: menuAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        const Center(child: Text('โหลดบริการไม่สำเร็จ')),
                    data: (categories) {
                      print("🔍 categories count: ${categories.length}");
                      print("🔍 looking for categoryId: ${widget.categoryId}");
                      for (var c in categories) {
                        print(
                          "   category id=${c.id} name=${c.catName} services=${c.services.length}",
                        );
                      }

                      final related = categories
                          .where((c) => c.id == service.categoryId)
                          .expand((c) => c.services)
                          .where((s) => s.id != widget.id)
                          .toList();

                      print("🔍 related count: ${related.length}");

                      if (related.isEmpty) {
                        return const Center(child: Text("ไม่มีบริการแนะนำ"));
                      }

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 0, right: 18),
                        itemCount: related.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 160,
                            child: ServiceCard(
                              data: related[index],
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
              text: isTechnician ? "เฉพาะลูกค้าเท่านั้น" : "จองคิว",
              onPressed: isTechnician
                  ? null
                  : () {
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
                                    int selectedIndex = -1;
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
                                                    borderRadius:
                                                        BorderRadius.circular(
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
                                                  color: AppColors
                                                      .colorTertiaryText,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              ...List.generate(options.length, (
                                                index,
                                              ) {
                                                final isSelected =
                                                    selectedIndex == index;

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
                                                        margin:
                                                            const EdgeInsets.only(
                                                              bottom: 8,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 24,
                                                              vertical: 12,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: isSelected
                                                              ? AppColors
                                                                    .primaryBGHover
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16,
                                                              ),
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? AppColors
                                                                      .secondary
                                                                : const Color(
                                                                    0xFFD6D6D6,
                                                                  ),
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
                                                                color: Color(
                                                                  0xFF0F53BA,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Radio<int>(
                                                              value: index,
                                                              groupValue:
                                                                  selectedIndex,
                                                              onChanged: (val) {
                                                                setState(() {
                                                                  selectedIndex =
                                                                      val!;
                                                                });
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    if (isSelected &&
                                                        index == 0) ...[
                                                      const SizedBox(height: 4),
                                                      const Text(
                                                        "  กรุณาเลือกเรทราคาที่ท่านต้องการ",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 8,
                                                        children: [
                                                          _priceTag(
                                                            label:
                                                                "ไม่เกิน ฿1,000",
                                                            value: 1000,
                                                            current:
                                                                selectedMaxPrice,
                                                            onTap: (v) {
                                                              setState(
                                                                () =>
                                                                    selectedMaxPrice =
                                                                        v,
                                                              );
                                                            },
                                                          ),
                                                          _priceTag(
                                                            label:
                                                                "ไม่เกิน ฿3,000",
                                                            value: 3000,
                                                            current:
                                                                selectedMaxPrice,
                                                            onTap: (v) {
                                                              setState(
                                                                () =>
                                                                    selectedMaxPrice =
                                                                        v,
                                                              );
                                                            },
                                                          ),
                                                          _priceTag(
                                                            label:
                                                                "ไม่เกิน ฿5,000",
                                                            value: 5000,
                                                            current:
                                                                selectedMaxPrice,
                                                            onTap: (v) {
                                                              setState(
                                                                () =>
                                                                    selectedMaxPrice =
                                                                        v,
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                    ],
                                                  ],
                                                );
                                              }),

                                              const SizedBox(height: 16),

                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TertiaryButton(
                                                      text: "ยกเลิก",
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      padding:
                                                          const EdgeInsets.symmetric(
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
                                                              Navigator.pop(
                                                                context,
                                                              );

                                                              if (selectedIndex ==
                                                                  0) {
                                                                Navigator.push(
                                                                  rootContext,
                                                                  MaterialPageRoute(
                                                                    builder: (context) => SystemChoose(
                                                                      serviceName: widget
                                                                          .data
                                                                          .serName,
                                                                      category: widget
                                                                          .data
                                                                          .categoryId,
                                                                      maxPrice:
                                                                          selectedMaxPrice ??
                                                                          5000,
                                                                      serviceId:
                                                                          widget
                                                                              .data
                                                                              .id,
                                                                      provinceId:
                                                                          widget
                                                                              .provinceId,
                                                                      data: widget
                                                                          .data,
                                                                    ),
                                                                  ),
                                                                );
                                                              } else {
                                                                Navigator.push(
                                                                  rootContext,
                                                                  MaterialPageRoute(
                                                                    builder: (context) => CustomerChoose(
                                                                      serviceName: widget
                                                                          .data
                                                                          .serName,
                                                                      category: widget
                                                                          .data
                                                                          .categoryId,
                                                                      serviceId:
                                                                          widget
                                                                              .data
                                                                              .id,
                                                                      provinceId:
                                                                          widget
                                                                              .provinceId,
                                                                      data: widget
                                                                          .data,
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          : null,
                                                      padding:
                                                          const EdgeInsets.symmetric(
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
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        );
      },
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
