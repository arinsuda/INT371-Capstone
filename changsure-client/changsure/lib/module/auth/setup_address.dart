import 'package:changsure/module/auth/start_page.dart';
import 'package:changsure/module/auth/technician/technician_register_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../core/button/primary_button.dart';
import '../../core/header.dart';
import '../../core/profile/controllers/address_form_controller.dart';
import '../../core/profile/widgets/address_form_fields.dart';
import '../../data/models/address_model.dart';
import '../../data/models/users/users_model.dart';
import '../../data/services/auth_service.dart';
import '../../state/master_data_provider.dart';
import '../../state/user_provider.dart';

class SetupAddress extends ConsumerStatefulWidget {
  final String? label;
  final String? phoneNumber;
  final String? addressLine;
  final String? subDistrict;
  final String? district;
  final String? province;
  final int? postCode;

  final int? provinceId;
  final int? districtId;
  final int? subDistrictId;

  final double? initialLat;
  final double? initialLng;

  final String email;
  final String password;
  final String confirmPassword;
  final String? firstname;
  final String? lastname;
  final String? phone;
  final List<String>? consents;

  const SetupAddress({
    super.key,
    this.label,
    this.phoneNumber,
    this.addressLine,
    this.subDistrict,
    this.district,
    this.province,
    this.postCode,
    this.provinceId,
    this.districtId,
    this.subDistrictId,
    this.initialLat,
    this.initialLng,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.firstname,
    this.lastname,
    this.phone,
    this.consents,
  });

  @override
  ConsumerState<SetupAddress> createState() => _SetupAddressState();
}

class _SetupAddressState extends ConsumerState<SetupAddress> {
  late TextEditingController labelCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressLineCtrl;
  late TextEditingController subDistrictCtrl;
  late TextEditingController districtCtrl;
  late TextEditingController provinceCtrl;
  late TextEditingController postCodeCtrl;

  final _formKey = GlobalKey<FormState>();

  final FocusNode _provinceFocusNode = FocusNode();
  final FocusNode _districtFocusNode = FocusNode();
  final FocusNode _subDistrictFocusNode = FocusNode();
  bool _isDirty = false;
  bool _phoneTouched = false;

  bool get _canSubmit {
    final formState = ref.read(addressFormProvider);

    return addressLineCtrl.text.trim().isNotEmpty &&
        formState.selectedProvinceId != null &&
        formState.selectedDistrictId != null &&
        formState.selectedSubDistrictId != null &&
        formState.selectedCoordinates != null;
  }

  @override
  void initState() {
    super.initState();

    labelCtrl = TextEditingController(text: widget.label ?? '');
    phoneCtrl = TextEditingController(text: widget.phoneNumber ?? '');
    addressLineCtrl = TextEditingController(text: widget.addressLine ?? '');
    subDistrictCtrl = TextEditingController(text: widget.subDistrict ?? '');
    districtCtrl = TextEditingController(text: widget.district ?? '');
    provinceCtrl = TextEditingController(text: widget.province ?? '');
    postCodeCtrl = TextEditingController(
      text: widget.postCode == null || widget.postCode == 0
          ? ''
          : widget.postCode.toString(),
    );

    phoneCtrl.addListener(() {
      _phoneTouched = true;
      _markDirty();
    });

    labelCtrl.addListener(_markDirty);
    addressLineCtrl.addListener(_markDirty);
    postCodeCtrl.addListener(_markDirty);

    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        final controller = ref.read(addressFormProvider.notifier);
      } catch (e) {
        if (mounted) {}
      }

      ref
          .read(addressFormProvider.notifier)
          .setInitialData(
            provinceId: widget.provinceId,
            districtId: widget.districtId,
            subDistrictId: widget.subDistrictId,
            zipCode: postCodeCtrl.text.isNotEmpty ? postCodeCtrl.text : null,
          );
    });
  }

  @override
  void dispose() {
    labelCtrl.dispose();
    phoneCtrl.dispose();
    addressLineCtrl.dispose();
    subDistrictCtrl.dispose();
    districtCtrl.dispose();
    provinceCtrl.dispose();
    postCodeCtrl.dispose();
    _provinceFocusNode.dispose();
    _districtFocusNode.dispose();
    _subDistrictFocusNode.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _onSave() async {
    final formState = ref.read(addressFormProvider);

    final isValidForm = _formKey.currentState?.validate() ?? false;

    final canSubmit =
        isValidForm &&
            formState.selectedProvinceId != null &&
            formState.selectedDistrictId != null &&
            formState.selectedSubDistrictId != null &&
            addressLineCtrl.text.trim().isNotEmpty &&
            formState.selectedCoordinates != null;

    if (!canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
      );
      return;
    }

    /// ✅ สร้าง address model (ใช้ทั้ง 2 flow)
    final address = RegisterAddressModel(
      label: labelCtrl.text.trim().isEmpty ? 'บ้าน' : labelCtrl.text.trim(),
      phoneNumber: phoneCtrl.text.trim().isEmpty
          ? widget.phone ?? ""
          : phoneCtrl.text.trim(),
      addressLine: addressLineCtrl.text.trim(),
      subDistrictId: formState.selectedSubDistrictId!,
      districtId: formState.selectedDistrictId!,
      provinceId: formState.selectedProvinceId!,
      latitude: formState.selectedCoordinates!.latitude,
      longitude: formState.selectedCoordinates!.longitude,
      isPrimary: true,
    );

    final hasConsents = widget.consents?.isNotEmpty ?? false;
    print("hasConsents: $hasConsents");

    /// 🟨 ================== TECHNICIAN FLOW ==================
    if (hasConsents) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TechnicianRegisterPage(
            email: widget.email,
            password: widget.password,
            confirmPassword: widget.confirmPassword,
            consents: widget.consents,
            address: address, // ✅ ส่ง address ไป
          ),
        ),
      );

      return; // 🔥 สำคัญมาก
    }

    /// 🟦 ================== USER FLOW ==================
    ref.read(addressFormProvider.notifier).setLoading(true);

    try {
      /// 1️⃣ REGISTER
      final model = CustomerRegisterModel(
        email: widget.email,
        password: widget.password,
        confirmPassword: widget.confirmPassword,
        firstname: widget.firstname ?? "",
        lastname: widget.lastname ?? "",
        phone: widget.phone ?? "",
        address: address,
      );

      await ref.read(customerRegisterProvider.notifier).register(model);

      final registerState = ref.read(customerRegisterProvider);

      if (registerState.hasError) {
        throw registerState.error!;
      }

      if (!(registerState.hasValue && registerState.value != null)) {
        throw Exception('สมัครสมาชิกไม่สำเร็จ');
      }

      /// 2️⃣ LOGIN
      final authService = AuthService();

      final result = await authService.login(
        widget.email,
        widget.password,
      );

      if (result == null) {
        throw Exception('Login ไม่สำเร็จ');
      }

      final token = result['access_token'] as String;
      final userId = result['user_id'] as int;
      final refreshToken = result['refresh_token'] as String;

      /// 3️⃣ GET PROFILE
      final profile = await authService.getCustomerProfile(
        token,
        userId,
      );

      /// 4️⃣ SAVE USER
      final user = UserModel(
        id: userId,
        email: widget.email,
        token: token,
        role: UserRole.customer,
        customerProfile: profile,
      );

      await ref.read(userProvider.notifier).login(
        user,
        refreshToken,
      );

      /// 5️⃣ NAVIGATE
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StartPage()),
            (route) => false,
      );
    } catch (e, st) {
      debugPrint("ERROR: $e");
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) {
        ref.read(addressFormProvider.notifier).setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(addressFormProvider).isLoading;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Header(
                header: "ที่อยู่ของฉัน",
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AddressFormFields(
                        labelCtrl: labelCtrl,
                        phoneCtrl: phoneCtrl,
                        addressLineCtrl: addressLineCtrl,
                        provinceCtrl: provinceCtrl,
                        districtCtrl: districtCtrl,
                        subDistrictCtrl: subDistrictCtrl,
                        postCodeCtrl: postCodeCtrl,
                        provinceFocusNode: _provinceFocusNode,
                        districtFocusNode: _districtFocusNode,
                        subDistrictFocusNode: _subDistrictFocusNode,
                        onFieldChanged: _markDirty,
                        showLabelField: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: PrimaryButton(
                        text: "ยืนยัน",
                        onPressed: (!_canSubmit || isLoading) ? null : _onSave,
                        padding: EdgeInsetsGeometry.symmetric(vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
