import 'package:changsure/core/header.dart';
import 'package:changsure/data/models/customer/customer_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/button/primary_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/state/user_provider.dart';
import '../../../core/profile/editProfile/phone_formatter.dart';
import '../../../data/services/customer_service.dart';
import '../../../state/bottom_nav_provider.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({super.key});

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isFormValid = ValueNotifier(false);
  late TextEditingController nameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  bool hasChanged = false;
  bool _isInitialized = false;

  CustomerModel? originalCustomer;

  void _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    isFormValid.value = isValid;
  }

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
  }

  void _initializeData() {
    if (_isInitialized) return;

    final user = ref.watch(userProvider);
    final customer = user?.customerProfile;
    originalCustomer = customer;

    String firstName = '';
    String lastName = '';
    if (customer?.fullName != null) {
      final parts = customer!.fullName.split(' ');
      if (parts.isNotEmpty) firstName = parts[0];
      if (parts.length > 1) lastName = parts.sublist(1).join(' ');
    }

    nameController.text = customer?.firstName ?? firstName;
    lastNameController.text = customer?.lastName ?? lastName;
    emailController.text = customer?.email ?? '';

    String rawPhone = customer?.phone ?? '';
    if (rawPhone.isNotEmpty &&
        rawPhone.length == 10 &&
        !rawPhone.contains('-')) {
      phoneController.text =
          "${rawPhone.substring(0, 3)}-${rawPhone.substring(3, 6)}-${rawPhone.substring(6)}";
    } else {
      phoneController.text = rawPhone;
    }

    nameController.addListener(_checkChanged);
    lastNameController.addListener(_checkChanged);
    emailController.addListener(_checkChanged);
    phoneController.addListener(_checkChanged);

    _isInitialized = true;
  }

  void _checkChanged() {
    setState(() {
      hasChanged = true;
    });
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(userProvider);

    if (user == null || user.token == null || originalCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบใหม่')),
      );
      return;
    }

    final rawPhone = phoneController.text.replaceAll('-', '');

    final updatedCustomer = originalCustomer!.copyWith(
      firstName: nameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      phone: rawPhone,
    );

    try {
      final success = await CustomerService().updateCustomer(
        user.token!, // ✅ safe แล้ว
        user.role,
        updatedCustomer,
      );

      if (success) {
        ref.read(userProvider.notifier)
            .updateCustomerProfile(updatedCustomer);

        ref.read(bottomSubPageProvider.notifier).state = null;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: (value) => _validateForm(),
          decoration: const InputDecoration(
            isDense: true, // ทำให้ช่องไม่สูงเกินไป
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16), // เว้นระยะห่างด้านล่างแต่ละช่อง
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      _initializeData();
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            children: [
              Header(header: "แก้ไขโปรไฟล์"),
              const SizedBox(height: 16),

              // ---------- Avatar ----------
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        'assets/image/Technician.png',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFFE8E8E8),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---------- Form Fields ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    buildTextField(
                      "ชื่อ",
                      nameController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "กรุณากรอกชื่อ";
                        if (v.length < 2)
                          return "ชื่อต้องมีอย่างน้อย 2 ตัวอักษร";
                        return null;
                      },
                    ),

                    buildTextField(
                      "นามสกุล",
                      lastNameController,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "กรุณากรอกนามสกุล" : null,
                    ),

                    buildTextField(
                      "อีเมล",
                      emailController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "กรุณากรอกอีเมล";
                        if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(v)) {
                          return "รูปแบบอีเมลไม่ถูกต้อง";
                        }
                        return null;
                      },
                    ),

                    buildTextField(
                      "เบอร์โทร",
                      phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhoneNumberFormatter()],
                      validator: (v) {
                        if (v == null || v.isEmpty) return "กรุณากรอกเบอร์โทร";
                        if (!RegExp(
                          r"^[0-9]{3}-[0-9]{3}-[0-9]{4}$",
                        ).hasMatch(v)) {
                          return "กรุณากรอกเบอร์โทรให้ถูกต้อง";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // ---------- Save Button ----------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 24,
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isFormValid,
                  builder: (context, valid, _) {
                    return PrimaryButton(
                      text: "บันทึกการแก้ไข",
                      onPressed: valid && hasChanged
                          ? _saveProfile
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
