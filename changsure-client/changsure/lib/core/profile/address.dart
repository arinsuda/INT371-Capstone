import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    await Geolocator.requestPermission();
    Position pos = await Geolocator.getCurrentPosition();

    setState(() {
      currentPosition = LatLng(pos.latitude, pos.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    final houseNumberController = TextEditingController(
      text: widget.houseNumber,
    );
    final subDistrictController = TextEditingController(
      text: widget.subDistrict,
    );
    final districtController = TextEditingController(text: widget.district);
    final provinceController = TextEditingController(text: widget.province);
    final postCodeController = TextEditingController(
      text: widget.postCode.toString(),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => {
                    Provider.of<BottomBarState>(
                      context,
                      listen: false,
                    ).closeSubPage(),
                  },
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "ดูที่อยู่ของฉัน",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004AAD),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
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
