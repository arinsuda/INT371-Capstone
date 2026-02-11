import 'package:changsure/core/profile/services/profile_services_provider.dart';
import 'package:changsure/core/profile/services/geocoding_cache_service.dart';
import 'package:changsure/core/profile/utils/debouncer.dart';
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

  const AddressFormState({
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddressFormState &&
        other.isLoading == isLoading &&
        other.isMapLoading == isMapLoading &&
        other.selectedCoordinates == selectedCoordinates &&
        other.selectedProvinceId == selectedProvinceId &&
        other.selectedDistrictId == selectedDistrictId &&
        other.selectedSubDistrictId == selectedSubDistrictId &&
        other.zipCode == zipCode;
  }

  @override
  int get hashCode {
    return Object.hash(
      isLoading,
      isMapLoading,
      selectedCoordinates,
      selectedProvinceId,
      selectedDistrictId,
      selectedSubDistrictId,
      zipCode,
    );
  }
}

class AddressFormController extends StateNotifier<AddressFormState> {
  final Ref ref;
  final Debouncer _geocodingDebouncer = Debouncer(
    delay: const Duration(milliseconds: 800),
  );

  AddressFormController(this.ref) : super(const AddressFormState());

  @override
  void dispose() {
    _geocodingDebouncer.dispose();
    super.dispose();
  }

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
    if (state.selectedSubDistrictId != id || state.zipCode != zipCode) {
      state = state.copyWith(selectedSubDistrictId: id, zipCode: zipCode);
    }
  }

  void setZipCode(String code) {
    if (state.zipCode != code) {
      state = state.copyWith(zipCode: code);
    }
  }

  void setCoordinates(LatLng coords) {
    final safeCoords = GeoBounds.clampOrDefault(coords);
    if (state.selectedCoordinates != safeCoords) {
      state = state.copyWith(selectedCoordinates: safeCoords);
    }
  }

  void clearCoordinates() {
    if (state.selectedCoordinates != null) {
      state = state.copyWith(clearCoordinates: true);
    }
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
    if (state.isLoading != value) {
      state = state.copyWith(isLoading: value);
    }
  }

  Future<void> useCurrentLocation() async {
    if (state.isMapLoading) return;

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
    // Return existing coordinates if available
    if (state.selectedCoordinates != null) {
      return state.selectedCoordinates!;
    }

    final geoService = ref.read(geocodingServiceProvider);
    final cacheService = ref.read(geocodingCacheProvider);

    // Try sub-district level
    if (subDistrict.isNotEmpty && district.isNotEmpty && province.isNotEmpty) {
      final address = "$subDistrict $district $province ประเทศไทย";

      // Check cache first
      final cached = cacheService.get(address);
      if (cached != null && GeoBounds.isInBounds(cached)) {
        return cached;
      }

      final p = await geoService.locationFromAddress(address);
      if (p != null && GeoBounds.isInBounds(p)) {
        cacheService.set(address, p);
        return p;
      }
    }

    // Try district level
    if (district.isNotEmpty && province.isNotEmpty) {
      final address = "$district $province ประเทศไทย";

      final cached = cacheService.get(address);
      if (cached != null && GeoBounds.isInBounds(cached)) {
        return cached;
      }

      final p = await geoService.locationFromAddress(address);
      if (p != null && GeoBounds.isInBounds(p)) {
        cacheService.set(address, p);
        return p;
      }
    }

    // Try province level
    if (province.isNotEmpty) {
      final address = "$province ประเทศไทย";

      final cached = cacheService.get(address);
      if (cached != null && GeoBounds.isInBounds(cached)) {
        return cached;
      }

      final p = await geoService.locationFromAddress(address);
      if (p != null && GeoBounds.isInBounds(p)) {
        cacheService.set(address, p);
        return p;
      }
    }

    // Try current location
    try {
      final current = await ref.read(locationServiceProvider).currentPosition();
      if (current != null && GeoBounds.isInBounds(current)) {
        return current;
      }
    } catch (_) {}

    // Default to Bangkok
    return const LatLng(13.7563, 100.5018);
  }

  void reset() {
    state = const AddressFormState();
  }
}

final addressFormProvider =
    StateNotifierProvider.autoDispose<AddressFormController, AddressFormState>(
      (ref) => AddressFormController(ref),
    );
