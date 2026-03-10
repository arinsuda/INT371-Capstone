import 'dart:io';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/module/auth/technician/widget/id_card_camera_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  static const Color _hintColor = Color(0xFF737373);

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
                  onTap: () async{
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
        const Text(
          "ตัวอย่างรูปถ่าย",
          style: TextStyle(fontSize: 14, color: _hintColor),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 230,
          width: double.infinity,
          child: idCardImage == null
              ? Image.asset(
            "assets/image/ID_Card.png",
            fit: BoxFit.contain,
          )
              : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              idCardImage!,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 32),

        ..._tips.map((tip) => _TipItem(text: tip)),
        const SizedBox(height: 24),
        PrimaryButton(
          text: "เริ่มสแกน",
          onPressed: _showSelectImageSource,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
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
