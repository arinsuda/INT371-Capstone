import 'dart:async';
import 'package:changsure/core/profile/services/profile_services_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';
import '../models/place_result.dart';
import '../utils/geo_bounds.dart';
import 'map_control_button.dart';

class MapPickerSheet extends ConsumerStatefulWidget {
  final LatLng initialCenter;
  final Function(LatLng) onPicked;

  const MapPickerSheet({
    super.key,
    required this.initialCenter,
    required this.onPicked,
  });

  @override
  ConsumerState<MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends ConsumerState<MapPickerSheet> {
  late final MapController mapController;
  late LatLng currentCenter;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _searching = false;
  bool _reverseLoading = false;
  String _prettyAddress = '';
  List<PlaceResult> _results = [];

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    currentCenter = widget.initialCenter;
    _reverseGeocode(currentCenter);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final p = await ref.read(locationServiceProvider).determinePosition();
      final dest = GeoBounds.clampOrDefault(p);
      mapController.move(dest, 16.5);
      setState(() => currentCenter = dest);
      _reverseGeocode(dest);
    } catch (_) {}
  }

  void _zoomIn() {
    final zoom = mapController.camera.zoom;
    mapController.move(currentCenter, (zoom + 1).clamp(3, 19).toDouble());
  }

  void _zoomOut() {
    final zoom = mapController.camera.zoom;
    mapController.move(currentCenter, (zoom - 1).clamp(3, 19).toDouble());
  }

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    final safe = GeoBounds.clampOrDefault(camera.center);
    currentCenter = safe;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _reverseGeocode(currentCenter);
    });

    setState(() {});
  }

  Future<void> _reverseGeocode(LatLng p) async {
    setState(() => _reverseLoading = true);
    final label = await ref.read(geocodingServiceProvider).reversePretty(p);
    if (!mounted) return;
    setState(() {
      _prettyAddress = label;
      _reverseLoading = false;
    });
  }

  Future<void> _searchPlaces(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);
    try {
      final items = await ref.read(nominatimServiceProvider).search(query);
      if (mounted) setState(() => _results = items);
    } catch (_) {
      // Handle error gracefully
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onTapResult(PlaceResult r) {
    final dest = GeoBounds.clampOrDefault(LatLng(r.lat, r.lon));
    mapController.move(dest, 16.5);
    setState(() {
      currentCenter = dest;
      _results = [];
    });
    _reverseGeocode(dest);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Container(
      height: h * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Stack(
        children: [
          // แผนที่
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: widget.initialCenter,
                initialZoom: 15.0,
                onPositionChanged: _onMapMoved,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (tapPosition, latLng) {
                  final dest = GeoBounds.clampOrDefault(latLng);
                  mapController.move(dest, mapController.camera.zoom);
                  setState(() => currentCenter = dest);
                  _reverseGeocode(dest);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.changsure.app',
                ),
              ],
            ),
          ),

          // หมุดกลางหน้าจอ
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 44),
              child: Icon(
                Icons.location_on,
                size: 54,
                color: AppColors.colorError,
              ),
            ),
          ),

          // ส่วนบนสุด: Search bar + Address display + Search results
          Positioned(
            top: 12,
            left: 12,
            right: 68, // เว้นที่สำหรับปุ่ม Close
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Material(
                    elevation: 6,
                    shadowColor: Colors.black12,
                    borderRadius: BorderRadius.circular(14),
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchPlaces,
                      onChanged: (v) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 350),
                          () => _searchPlaces(v),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'ค้นหาสถานที่ / ที่อยู่',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : (_searchCtrl.text.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _results = []);
                                        FocusScope.of(context).unfocus();
                                      },
                                    )),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Address display
                  Container(
                    width: w - 24 - 56, // 24 = padding, 56 = เว้นปุ่ม Close
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _reverseLoading
                                ? 'กำลังดึงที่อยู่...'
                                : (_prettyAddress.isEmpty
                                      ? 'เลื่อนแผนที่เพื่อเลือกตำแหน่ง'
                                      : _prettyAddress),
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search results
                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: h * 0.32,
                          maxWidth: w - 24 - 56,
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final r = _results[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_searching),
                              title: Text(
                                r.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _onTapResult(r),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ปุ่มควบคุมแผนที่ (ขวา)
          Positioned(
            right: 14,
            bottom: 180,
            child: SafeArea(
              child: Column(
                children: [
                  MapControlButton(icon: Icons.add, onTap: _zoomIn),
                  const SizedBox(height: 10),
                  MapControlButton(icon: Icons.remove, onTap: _zoomOut),
                  const SizedBox(height: 10),
                  MapControlButton(
                    icon: Icons.my_location,
                    onTap: _moveToCurrentLocation,
                  ),
                ],
              ),
            ),
          ),

          // ปุ่มปิด (ขวาบน)
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: Material(
                color: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ส่วนล่าง: แสดง Lat/Lng และปุ่มยืนยัน
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 14),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lat ${currentCenter.latitude.toStringAsFixed(6)} • Lng ${currentCenter.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      text: "ยืนยันตำแหน่งนี้",
                      onPressed: () {
                        widget.onPicked(currentCenter);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
