import 'dart:convert';
import 'package:changsure/core/button/primaryButton.dart';
import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../state/bottomBarState.dart';
import '../theme.dart';

class Address extends StatefulWidget {
  final String houseNumber;
  final String subDistrict;
  final String district;
  final String province;
  final int postCode;

  const Address({
    super.key,
    required this.houseNumber,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.postCode,
  });

  @override
  State<Address> createState() => _AddressState();
}

class _AddressState extends State<Address> {
  LatLng? currentPosition;
  final mapController = MapController();

  // controllers
  late TextEditingController houseNumberController;
  late TextEditingController subDistrictController;
  late TextEditingController districtController;
  late TextEditingController provinceController;
  late TextEditingController postCodeController;

  // track if anything changed
  bool hasChanged = false;

  @override
  void initState() {
    super.initState();
    getLocation();

    // init controllers
    houseNumberController = TextEditingController(text: widget.houseNumber);
    subDistrictController = TextEditingController(text: widget.subDistrict);
    districtController = TextEditingController(text: widget.district);
    provinceController = TextEditingController(text: widget.province);
    postCodeController = TextEditingController(
      text: widget.postCode.toString(),
    );

    // add listener เพื่อเช็คการเปลี่ยนแปลง
    houseNumberController.addListener(_checkChanged);
    subDistrictController.addListener(_checkChanged);
    districtController.addListener(_checkChanged);
    provinceController.addListener(_checkChanged);
    postCodeController.addListener(_checkChanged);
  }

  void _checkChanged() {
    final changed =
        houseNumberController.text != widget.houseNumber ||
        subDistrictController.text != widget.subDistrict ||
        districtController.text != widget.district ||
        provinceController.text != widget.province ||
        postCodeController.text != widget.postCode.toString();

    if (changed != hasChanged) {
      setState(() {
        hasChanged = changed;
      });
    }
  }

  Future<void> getLocation() async {
    await Geolocator.requestPermission();
    Position pos = await Geolocator.getCurrentPosition();

    setState(() {
      currentPosition = LatLng(pos.latitude, pos.longitude);
    });
  }

  @override
  void dispose() {
    houseNumberController.dispose();
    subDistrictController.dispose();
    districtController.dispose();
    provinceController.dispose();
    postCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Header(header: "ดูที่อยู่ของฉัน"),
            const SizedBox(height: 16),

            // Container(
            //   height: 250,
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(12),
            //     border: Border.all(color: AppColors.colorStroke),
            //   ),
            //   child: currentPosition == null
            //       ? const Center(child: CircularProgressIndicator())
            //       : ClipRRect(
            //           borderRadius: BorderRadius.circular(12),
            //           child: FlutterMap(
            //             mapController: mapController,
            //             options: MapOptions(
            //               initialCenter: currentPosition!,
            //               initialZoom: 16,
            //               interactionOptions: const InteractionOptions(
            //                 flags:
            //                     InteractiveFlag.all & ~InteractiveFlag.rotate,
            //               ),
            //             ),
            //             children: [
            //               TileLayer(
            //                 urlTemplate:
            //                     "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            //               ),
            //               MarkerLayer(
            //                 markers: [
            //                   Marker(
            //                     point: currentPosition!,
            //                     width: 40,
            //                     height: 40,
            //                     child: const Icon(
            //                       Icons.location_pin,
            //                       color: AppColors.primary,
            //                       size: 40,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ],
            //           ),
            //         ),
            // ),
            // const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              // ปรับ horizontal เป็น 6
              child: Column(
                children: [
                  _buildTextArea(
                    "บ้านเลขที่, หมู่, ชื่ออาคาร/หมู่บ้าน, ซอย, ถนน",
                    houseNumberController,
                  ),
                  _buildTextField("แขวง/ตำบล", subDistrictController),
                  _buildTextField("เขต/อำเภอ", districtController),
                  _buildTextField("จังหวัด", provinceController),
                  _buildTextField("รหัสไปรษณี", postCodeController),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: PrimaryButton(
                text: "ยืนยัน",
                onPressed: hasChanged
                    ? () {
                        // ทำงานตอนกด
                      }
                    : null, // null = disabled
              ),
            ),
            const SizedBox(height: 24,)
          ],
        ),
      ),
    );
  }
}

Widget _buildTextField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.colorTertiaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.colorStroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryBorder,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTextArea(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.colorTertiaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 5, // หรือใช้ null ถ้าอยากให้ขยายอัตโนมัติ
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: 'เขียนรายละเอียดเกี่ยวกับตัวคุณ...',
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.colorStroke),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.colorStroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryBorder,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
