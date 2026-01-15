import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:changsure/core/theme.dart';

class MapPreview extends StatefulWidget {
  final MapController mapController;
  final LatLng defaultCenter;
  final LatLng? selectedCoordinates;

  final VoidCallback onTapOpenPicker;
  final VoidCallback onTapCurrentLocation;

  final bool isMapLoading;

  const MapPreview({
    super.key,
    required this.mapController,
    required this.defaultCenter,
    required this.selectedCoordinates,
    required this.onTapOpenPicker,
    required this.onTapCurrentLocation,
    required this.isMapLoading,
  });

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  @override
  void didUpdateWidget(MapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ถ้ามีการเปลี่ยน selectedCoordinates ให้เลื่อนแผนที่ไปที่ตำแหน่งใหม่
    if (widget.selectedCoordinates != null &&
        oldWidget.selectedCoordinates != widget.selectedCoordinates) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.mapController.move(widget.selectedCoordinates!, 15.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ใช้พิกัดที่เลือก ถ้าไม่มีให้ใช้พิกัดเริ่มต้น
    final displayCoords = widget.selectedCoordinates ?? widget.defaultCenter;

    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onTapOpenPicker,
            child: FlutterMap(
              mapController: widget.mapController,
              options: MapOptions(
                initialCenter: displayCoords,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.changsure.app',
                  // เพิ่มการจัดการ error
                  errorTileCallback: (tile, error, stackTrace) {
                    debugPrint('Map tile error: $error');
                  },
                ),
                // แสดงหมุดเสมอเมื่อมีพิกัด (ไม่ว่าจะเป็น default หรือ selected)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: displayCoords,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.colorError,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ปุ่ม Current Location (ซ้ายล่าง)
          Positioned(
            bottom: 16,
            left: 16,
            child: InkWell(
              onTap: widget.onTapCurrentLocation,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.isMapLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.near_me, color: Colors.black54),
              ),
            ),
          ),

          // แสดง Lat, Lng (ขวาล่าง)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Lat: ${displayCoords.latitude.toStringAsFixed(6)}\nLng: ${displayCoords.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
