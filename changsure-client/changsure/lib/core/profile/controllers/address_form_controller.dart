import 'package:changsure/core/profile/services/profile_services_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../utils/geo_bounds.dart';

class AddressFormState {
  final bool isLoading;
  final bool isMapLoading;
  final LatLng? selectedCoordinates;

  final int? selectedProvinceId;
  final int? selectedDistrictId;
  final int? selectedSubDistrictId;

  final String? zipCode;

  AddressFormState({
    this.isLoading = false,
    this.isMapLoading = false,
    this.selectedCoordinates,
    this.selectedProvinceId,
    this.selectedDistrictId,
    this.selectedSubDistrictId,
    this.zipCode,
  });

  AddressFormState copyWith({
    bool? isLoading,
    bool? isMapLoading,
    LatLng? selectedCoordinates,
    int? selectedProvinceId,
    int? selectedDistrictId,
    int? selectedSubDistrictId,
    String? zipCode,
    bool clearCoordinates = false,
  }) {
    return AddressFormState(
      isLoading: isLoading ?? this.isLoading,
      isMapLoading: isMapLoading ?? this.isMapLoading,
      selectedCoordinates: clearCoordinates
          ? null
          : (selectedCoordinates ?? this.selectedCoordinates),
      selectedProvinceId: selectedProvinceId ?? this.selectedProvinceId,
      selectedDistrictId: selectedDistrictId ?? this.selectedDistrictId,
      selectedSubDistrictId:
          selectedSubDistrictId ?? this.selectedSubDistrictId,
      zipCode: zipCode ?? this.zipCode,
    );
  }
}

class AddressFormController extends StateNotifier<AddressFormState> {
  final Ref ref;

  AddressFormController(this.ref) : super(AddressFormState());

  void setProvinceId(int? id) {
    if (state.selectedProvinceId != id) {
      state = state.copyWith(
        selectedProvinceId: id,
        selectedDistrictId: null,
        selectedSubDistrictId: null,
        zipCode: null,
      );
    }
  }

  void setDistrictId(int? id) {
    if (state.selectedDistrictId != id) {
      state = state.copyWith(
        selectedDistrictId: id,
        selectedSubDistrictId: null,
        zipCode: null,
      );
    }
  }

  void setSubDistrictId(int? id, {String? zipCode}) {
    state = state.copyWith(selectedSubDistrictId: id, zipCode: zipCode);
  }

  void setZipCode(String code) {
    state = state.copyWith(zipCode: code);
  }

  void setCoordinates(LatLng coords) {
    final safeCoords = GeoBounds.clampOrDefault(coords);
    state = state.copyWith(selectedCoordinates: safeCoords);
  }

  void clearCoordinates() {
    state = state.copyWith(clearCoordinates: true);
  }

  void setInitialData({
    int? provinceId,
    int? districtId,
    int? subDistrictId,
    String? zipCode,
    LatLng? coords,
  }) {
    LatLng? validCoords;
    if (coords != null && GeoBounds.isInBounds(coords)) {
      validCoords = coords;
    }

    state = AddressFormState(
      selectedProvinceId: provinceId,
      selectedDistrictId: districtId,
      selectedSubDistrictId: subDistrictId,
      zipCode: zipCode,
      selectedCoordinates: validCoords,
    );
  }

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  Future<void> useCurrentLocation() async {
    state = state.copyWith(isMapLoading: true);
    try {
      final locService = ref.read(locationServiceProvider);
      final pos = await locService.determinePosition();
      final safePos = GeoBounds.clampOrDefault(pos);
      state = state.copyWith(selectedCoordinates: safePos, isMapLoading: false);
    } catch (e) {
      state = state.copyWith(isMapLoading: false);
      rethrow;
    }
  }

  Future<LatLng> getSmartStartingPoint({
    required String subDistrict,
    required String district,
    required String province,
  }) async {
    if (state.selectedCoordinates != null) {
      return state.selectedCoordinates!;
    }

    final geoService = ref.read(geocodingServiceProvider);

    if (subDistrict.isNotEmpty && district.isNotEmpty && province.isNotEmpty) {
      final p = await geoService.locationFromAddress(
        "$subDistrict $district $province ประเทศไทย",
      );
      if (p != null && GeoBounds.isInBounds(p)) return p;
    }

    if (district.isNotEmpty && province.isNotEmpty) {
      final p = await geoService.locationFromAddress(
        "$district $province ประเทศไทย",
      );
      if (p != null && GeoBounds.isInBounds(p)) return p;
    }

    if (province.isNotEmpty) {
      final p = await geoService.locationFromAddress("$province ประเทศไทย");
      if (p != null && GeoBounds.isInBounds(p)) return p;
    }

    try {
      final current = await ref.read(locationServiceProvider).currentPosition();
      if (current != null && GeoBounds.isInBounds(current)) {
        return current;
      }
    } catch (_) {}

    return const LatLng(13.7563, 100.5018);
  }

  void reset() {
    state = AddressFormState();
  }
}

final addressFormProvider =
    StateNotifierProvider.autoDispose<AddressFormController, AddressFormState>(
      (ref) => AddressFormController(ref),
    );
