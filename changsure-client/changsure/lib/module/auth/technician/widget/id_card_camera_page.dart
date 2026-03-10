import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../../../../main/main.dart';
import 'crop_id_card_page.dart';

class IdCardCameraPage extends StatefulWidget {
  const IdCardCameraPage({super.key});

  @override
  State<IdCardCameraPage> createState() => _IdCardCameraPageState();
}

class _IdCardCameraPageState extends State<IdCardCameraPage> {

  late CameraController controller;

  @override
  void initState() {
    super.initState();

    controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
    );

    controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future takePhoto() async {
    final image = await controller.takePicture();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CropIdCardPage(
          imagePath: image.path,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (!controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [

          /// preview
          CameraPreview(controller),

          /// กรอบบัตร
          Center(
            child: Container(
              width: 320,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
            ),
          ),

          /// ปุ่มถ่าย
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: takePhoto,
                child: const Icon(Icons.camera_alt_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }
}