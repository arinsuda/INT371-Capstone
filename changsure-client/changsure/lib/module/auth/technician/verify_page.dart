import 'dart:io';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/module/auth/technician/widget/id_card_camera_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme.dart';
import '../start_page.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  static const Color _hintColor = Color(0xFF737373);
  bool isSubmitted = false;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🟣 AFTER SUBMIT
        if (isSubmitted) ...[
          const SizedBox(height: 32),

          Center(
            child: Image.asset("assets/image/waiting_for_verify.png", width: 300),
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

            PrimaryButton(
              text: "เริ่มสแกน",
              onPressed: _showSelectImageSource,
              padding: const EdgeInsets.symmetric(vertical: 8),
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

            const SizedBox(height: 24),

            PrimaryButton(
              text: "ยืนยัน",
              onPressed: () {
                setState(() {
                  isSubmitted = true;
                  idCardImage = null;
                });
              },
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
