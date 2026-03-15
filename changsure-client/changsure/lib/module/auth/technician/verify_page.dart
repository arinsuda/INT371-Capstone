import 'dart:io';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/module/auth/technician/technician_register_step_provider.dart';
import 'package:changsure/module/auth/technician/unverify_page.dart';
import 'package:changsure/module/auth/technician/widget/id_card_camera_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/button/tertiary_button.dart';
import '../../../core/theme.dart';
import '../../../state/user_provider.dart';
import '../start_page.dart';

class VerifyPage extends ConsumerStatefulWidget {
  const VerifyPage({super.key});

  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> {
  static const Color _hintColor = Color(0xFF737373);
  bool isSubmitted = false;
  bool isChecking = false;

  final List<String> _tips = [
    "โปรดอยู่ในที่แสงสว่างเพียงพอ",
    "หลีกเลี่ยงแสงสะท้อนบนบัตร",
    "รูปถ่ายและข้อมูลบนบัตรชัดเจน",
  ];

  final ImagePicker _picker = ImagePicker();

  File? idCardImage;

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image != null) {
      setState(() {
        idCardImage = File(image.path);
      });
    }
  }

  void _showSelectImageSource() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 8, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text("ถ่ายรูปบัตรใหม่"),
                  onTap: () async {
                    Navigator.pop(context);

                    final image = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IdCardCameraPage(),
                      ),
                    );

                    if (image != null) {
                      setState(() {
                        idCardImage = image;
                      });
                    }
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.photo),
                  title: const Text("อัปโหลดรูปจากเครื่อง"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final verifyState = ref.watch(verifyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🟣 AFTER SUBMIT
        if (isSubmitted) ...[
          const SizedBox(height: 32),

          Center(
            child: Image.asset(
              "assets/image/waiting_for_verify.png",
              width: 300,
            ),
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              "กรุณารอการตรวจสอบ",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 10),

          const Center(
            child: Text(
              "ระบบใช้เวลาในการตรวจสอบยืนยันตัวตน 7-15 วันทำการ",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.primaryText),
            ),
          ),

          const SizedBox(height: 32),

          PrimaryButton(
            text: "กลับหน้าหลัก",
            onPressed: () {
              ref.read(userProvider.notifier).refreshUser();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const StartPage()),
                (route) => false,
              );
            },
            padding: EdgeInsetsGeometry.symmetric(vertical: 8),
          ),
        ]
        /// 🔵 NORMAL STATE
        else ...[
          const Text(
            "บัตรประชาชน",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text(
            "โปรดสแกนรูปบัตรประชาชนของคุณ",
            style: TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 32),

          /// BEFORE UPLOAD
          if (idCardImage == null) ...[
            const Text(
              "ตัวอย่างรูปถ่าย",
              style: TextStyle(fontSize: 14, color: _hintColor),
            ),

            const SizedBox(height: 10),

            Image.asset("assets/image/ID_Card.png", fit: BoxFit.contain),

            const SizedBox(height: 32),

            ..._tips.map((tip) => _TipItem(text: tip)),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(
                children: [
                  Expanded(
                    child: TertiaryButton(
                      text: "ย้อนกลับ",
                      onPressed: () {
                        ref
                            .read(technicianRegisterStepProvider.notifier)
                            .state--;
                      },
                      padding: EdgeInsetsGeometry.symmetric(vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: "เริ่มสแกน",
                      onPressed: _showSelectImageSource,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],

          /// AFTER UPLOAD
          if (idCardImage != null) ...[
            const Text(
              "บัตรของคุณ",
              style: TextStyle(fontSize: 16, color: _hintColor),
            ),

            const SizedBox(height: 10),

            AspectRatio(
              aspectRatio: 1.6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(idCardImage!, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showSelectImageSource,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF9FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.camera_alt, size: 18),
                      SizedBox(width: 12),
                      Text("ถ่ายอีกครั้ง", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(
                children: [
                  Expanded(
                    child: TertiaryButton(
                      text: "ย้อนกลับ",
                      onPressed: () {
                        ref
                            .read(technicianRegisterStepProvider.notifier)
                            .state--;
                      },
                      padding: EdgeInsetsGeometry.symmetric(vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: isChecking ? "กำลังตรวจสอบ..." : "ยืนยัน",
                      padding: EdgeInsetsGeometry.symmetric(vertical: 8),
                      onPressed: (verifyState.isLoading || isChecking)
                          ? null
                          : () async {
                              if (idCardImage == null) return;

                              setState(() {
                                isChecking = true;
                              });
                              final jobId = await ref
                                  .read(verifyProvider.notifier)
                                  .verify(idCardImage!);

                              if (jobId == null) {
                                setState(() => isChecking = false);
                                return;
                              }

                              print("JobId $jobId");

                              await Future.delayed(const Duration(seconds: 10));
                              final result = await ref.read(
                                verifyDetailProvider(jobId).future,
                              );

                              print("Verify $result");

                              if (result?.verifyStatus == "FAILED") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UnverifyPage(),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                isChecking = false;
                                isSubmitted = true;
                                idCardImage = null;
                              });
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    const hintColor = Color(0xFF737373);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_outlined),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14, color: hintColor)),
        ],
      ),
    );
  }
}
