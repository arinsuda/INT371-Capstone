import 'dart:io';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/data/models/technician/technician_model.dart';
import 'package:changsure/module/auth/technician/passed_verify.dart';
import 'package:changsure/module/auth/technician/setup_technician_profile.dart';
import 'package:changsure/module/auth/technician/technician_register_step_provider.dart';
import 'package:changsure/module/auth/technician/unverify_page.dart';
import 'package:changsure/module/auth/technician/widget/id_card_camera_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/button/tertiary_button.dart';
import '../../../core/theme.dart';
import '../../../data/models/users/users_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../state/user_provider.dart';
import '../start_page.dart';

class VerifyPage extends ConsumerStatefulWidget {
  final String email;
  final String password;

  const VerifyPage({super.key, required this.email, required this.password});

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

  Future<VerifyTechnician?> _pollJobStatus(int jobId, String token) async {
    const maxAttempts = 40;
    const interval = Duration(seconds: 3);

    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(interval);

      ref.invalidate(verifyDetailProvider((jobId, token)));

      final status = await ref.read(
        verifyDetailProvider((jobId, token)).future,
      );

      if (status == null) continue;
      if (status.verifyStatus == null || status.verifyStatus!.isEmpty) continue;

      final vs = status.verifyStatus!.toUpperCase();
      if (vs == 'PASSED' ||
          vs == 'FAILED' ||
          vs == 'PENDING' ||
          vs == 'OCR_FAILED' ||
          vs == 'NAME_MISMATCH' ||
          vs == 'REJECTED') {
        return status;
      }
    }
    return null;
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
                              setState(() => isChecking = true);

                              try {
                                // STEP 1: upload + enqueue
                                final jobId = await ref
                                    .read(verifyProvider.notifier)
                                    .verify(idCardImage!);

                                if (jobId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('อัปโหลดบัตรไม่สำเร็จ'),
                                    ),
                                  );
                                  return;
                                }

                                // STEP 2: auto login
                                final authService = AuthService();
                                final result = await authService.login(
                                  widget.email,
                                  widget.password,
                                );
                                if (result == null)
                                  throw Exception("Auto login failed");

                                final roleStr = (result['role'] as String)
                                    .toUpperCase();
                                final user = UserModel(
                                  id: result['user_id'] as int,
                                  token: result['access_token'] as String,
                                  role: roleStr == 'TECHNICIAN'
                                      ? UserRole.technician
                                      : UserRole.customer,
                                );
                                await ref
                                    .read(userProvider.notifier)
                                    .login(
                                      user,
                                      result['refresh_token'] as String,
                                    );

                                final preToken = ref
                                    .read(technicianRegisterDataProvider)
                                    .preVerifiedToken!;

                                // STEP 3: poll จนกว่าจะได้ผล (real-time)
                                final verifyResult = await _pollJobStatus(
                                  jobId,
                                  preToken,
                                );

                                if (verifyResult == null) {
                                  // timeout → ถือว่า PENDING
                                  setState(() {
                                    isSubmitted = true;
                                    idCardImage = null;
                                  });
                                  return;
                                }

                                // STEP 4: route ตาม status
                                final vs =
                                    verifyResult.verifyStatus?.toUpperCase() ??
                                    '';

                                if (vs == 'FAILED' || vs == 'REJECTED') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const UnverifyPage(),
                                    ),
                                  );
                                  return;
                                }

                                if (vs == 'PASSED') {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const PassedVerify(),
                                    ),
                                    (route) => false,
                                  );
                                  return;
                                }

                                // PENDING / OCR_FAILED / NAME_MISMATCH
                                setState(() {
                                  isSubmitted = true;
                                  idCardImage = null;
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'เกิดข้อผิดพลาด กรุณาลองใหม่',
                                    ),
                                  ),
                                );
                              } finally {
                                setState(() => isChecking = false);
                              }
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
