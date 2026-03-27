import 'dart:io';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme.dart';
import '../../../data/models/customer/customer_model.dart';
import '../../../state/user_provider.dart';

class ReviewPage extends ConsumerStatefulWidget {
  final List<String>? serviceImage;
  final String serviceName;
  final int bookingId; // 🔥 ต้องมี

  const ReviewPage({
    super.key,
    required this.serviceImage,
    required this.serviceName,
    required this.bookingId,
  });

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  int rating = 0;
  List<File> selectedImages = [];
  final TextEditingController controller = TextEditingController();

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final pickedFiles = await picker.pickMultiImage(); // เลือกหลายรูป

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        selectedImages.addAll(
          pickedFiles.map((e) => File(e.path)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("bookingId: ${widget.bookingId}");
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Header(header: "ให้คะแนน"),
              const SizedBox(height: 16),

              // ── Service Info ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.serviceImage!.first,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "บริการทาสีภายใน เกรดวัสดุพรีเมียม",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "฿400",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Rating ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "ให้คะแนนการบริการ",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.colorTertiaryText,
                    ),
                  ),
                ),
              ),

              Row(
                children: List.generate(5, (index) {
                  final isSelected = index < rating;

                  return IconButton(
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                    icon: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      size: 30,
                      color: isSelected
                          ? const Color(0xFFFFC53D) // เหลืองตอนเลือก
                          : Colors.grey, // เทาตอนยังไม่เลือก
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // ── Comment ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "ความคิดเห็น",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.colorTertiaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.colorStroke),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: controller,
                        maxLines: 5,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: "โปรดระบุความคิดเห็นของคุณ",
                          hintStyle: TextStyle(
                            color: AppColors.colorTertiaryText,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),

                          // ❗ ซ่อน counter เดิม
                          counterText: "",
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ✅ counter ใหม่อยู่นอกกล่อง
                    Text(
                      "${controller.text.length} / 500",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.colorTertiaryText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Upload Image ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "เพิ่มรูปภาพ",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.colorTertiaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child:
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // 🔹 ปุ่มเพิ่มรูป
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: 90,
                          height: 90,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 30,
                            color: AppColors.primaryBorder,
                          ),
                        ),
                      ),

                      // 🔹 preview รูป
                      ...selectedImages.map((file) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(file),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            // ❌ ปุ่มลบ
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedImages.remove(file);
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Submit Button ─────────────────────────────
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: "ยืนยัน",
                  onPressed: () async {
                    print("Rating => ${rating}");
                    if (rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("กรุณาให้คะแนน")),
                      );
                      return;
                    }

                    await ref.read(reviewNotifierProvider.notifier).createReview(
                      bookingId: widget.bookingId,
                      rating: rating,
                      comment: controller.text.trim().isEmpty ? null : controller.text.trim(),
                      images: selectedImages, // ✅ List<File>
                    );

                    final state = ref.read(reviewNotifierProvider);

                    state.when(
                      data: (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("รีวิวสำเร็จ")),
                        );
                        Navigator.pop(context); // 🔥 บอกว่ารีวิวแล้ว
                      },
                      loading: () {},
                      error: (e, _) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
                        );
                      },
                    );
                  },
                  padding: EdgeInsets.symmetric(vertical: 10),
                  borderRadius: 12,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
