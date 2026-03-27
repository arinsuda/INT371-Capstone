import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class CropIdCardPage extends StatefulWidget {
  final String imagePath;

  const CropIdCardPage({super.key, required this.imagePath});

  @override
  State<CropIdCardPage> createState() => _CropIdCardPageState();
}

class _CropIdCardPageState extends State<CropIdCardPage> {
  File? croppedFile;

  @override
  void initState() {
    super.initState();
    cropImage();
  }

  Future cropImage() async {
    final result = await ImageCropper().cropImage(
      sourcePath: widget.imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 1.6, ratioY: 1),
    );

    if (result != null) {
      setState(() {
        croppedFile = File(result.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (croppedFile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("ตรวจสอบรูปบัตร")),
      body: Column(
        children: [
          Expanded(child: Image.file(croppedFile!)),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("ถ่ายใหม่"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, croppedFile);
                    },
                    child: const Text("ยืนยัน"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
