import 'package:changsure/module/home/service/systemChoose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/button/primaryButton.dart';
import '../../../core/button/tertiaryButton.dart';
import '../../../core/theme.dart';
import '../../../mockDB/serviceCategories.dart';
import '../homePage/serviceCard.dart';
import 'customerChoose.dart';

class ServiceDetail extends StatelessWidget {
  final int id;
  final SubServiceDetail data;

  const ServiceDetail({super.key, required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    // ดึงหมวดของบริการนี้
    final category = mockServiceCategories.firstWhere(
      (cat) =>
          cat.name == data.category ||
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
            padding: EdgeInsets.only(
              top: 0,
              bottom: 16, // ใช้ค่าจากระบบ
            ),
            children: [
              Stack(
                children: [
                  Container(
                    height: 370,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/image/clean3.png"),
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
                          "${data.price}",
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
                      data.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      data.subDetails,
                      style: const TextStyle(
                        fontSize: 12,
                        // fontWeight: FontWeight.bold,
                        color: Color(0xFF002C8C),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 24,
                color: AppColors.primaryBGHover, // สีที่ต้องการ
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "รายละเอียด",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),

                    SizedBox(height: 4),

                    MarkdownBody(
                      data: data.description,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 14,
                          color: AppColors.colorTertiaryText,
                        ),
                        listBullet: TextStyle(
                          fontSize: 16,
                          color: AppColors.colorTertiaryText,
                        ),
                        listIndent: 18.0, // ระยะห่าง bullet กับข้อความ
                        blockSpacing: 4.0,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 24,
                color: AppColors.primaryBGHover, // สีที่ต้องการ
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "เงื่อนไขเพิ่มเติม",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),

                    SizedBox(height: 4),

                    MarkdownBody(
                      data: data.conditions,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 14,
                          color: AppColors.colorTertiaryText,
                        ),
                        listBullet: TextStyle(
                          fontSize: 16,
                          color: AppColors.colorTertiaryText,
                        ),
                        listIndent: 18.0, // ระยะห่าง bullet กับข้อความ
                        blockSpacing: 4.0,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 24,
                color: AppColors.primaryBGHover, // สีที่ต้องการ
              ),

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
                              child: ServiceCard(data: subService),
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
          bottom: MediaQuery.of(context).padding.bottom + 24, // ใช้ค่าจากระบบ
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // shadow เบา
              blurRadius: 5,
              offset: const Offset(0, -2), // ขึ้นด้านบนเล็กน้อย
            ),
          ],
        ),
        child: PrimaryButton(
          text: "จองคิว",
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              // ให้ด้านหลังเป็นสีดำ opacity
              isScrollControlled: true,
              builder: (context) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    color: Colors.black.withOpacity(0.5), // background ด้านหลัง
                    child: GestureDetector(
                      onTap: () {}, // กันไม่ให้ tap ด้านใน dismiss
                      child: DraggableScrollableSheet(
                        initialChildSize: 0.53, // ความสูงเริ่มต้นของ modal
                        maxChildSize: 0.53,
                        minChildSize: 0.3,
                        builder: (context, scrollController) {
                          int selectedIndex = -1; // สถานะเลือก

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
                                                        ); // สีเมื่อเลือกแล้ว
                                                      }
                                                      return Color(
                                                        0xFFD6D6D6,
                                                      ); // สีเมื่อยังไม่ได้เลือก
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
                                        // ปุ่มบันทึก
                                        Expanded(
                                          child: PrimaryButton(
                                            text: "ยืนยัน",
                                            onPressed: () {
                                              if (selectedIndex == -1)
                                                return; // ยังไม่ได้เลือก อาจแจ้งเตือนก็ได้
                                              Navigator.pop(
                                                context,
                                              ); // ปิด modal ก่อน
                                              if (selectedIndex == 0) {
                                                // ระบบเลือกช่างให้อัตโนมัติ
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        SystemChoose(
                                                          serviceName:
                                                              data.name,  category: 'ทาสี'
                                                        ),
                                                  ),
                                                );
                                              } else if (selectedIndex == 1) {
                                                // เลือกช่างด้วยตนเอง
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CustomerChoose(
                                                          serviceName:
                                                              data.name, category: 'ทาสี',
                                                        ),
                                                  ),
                                                );
                                              }
                                            },
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
