import 'dart:io';

import 'package:changsure/module/auth/setup_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/header.dart';
import '../../../core/profile/editProfile/phone_formatter.dart';
import '../../../data/services/customer_service.dart';
import '../../../state/master_data_provider.dart';
import '../../../state/user_provider.dart';

class SetupProfilePage extends ConsumerStatefulWidget {
  final String email;
  const SetupProfilePage({super.key, required this.email});

  @override
  ConsumerState<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends ConsumerState<SetupProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isFormValid = ValueNotifier(false);
  bool hasChanged = false;
  late TextEditingController nameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  String? _originalFirstName;
  String? _originalLastName;
  String? _originalEmail;
  String? _originalPhone;
  String? avatarUrl;
  dynamic originalCustomer;
  File? selectedImage;


  @override
  void initState() {
    super.initState();

    final user = ref.read(userProvider);
    final customer = user?.customerProfile;
    originalCustomer = customer;

    String firstName = '';
    String lastName = '';
    if (customer?.fullName != null) {
      final parts = customer!.fullName.split(' ');
      if (parts.isNotEmpty) firstName = parts[0];
      if (parts.length > 1) lastName = parts.sublist(1).join(' ');
    }

    _originalFirstName = customer?.firstName ?? firstName;
    _originalLastName = customer?.lastName ?? lastName;
    _originalEmail = widget.email.isNotEmpty
        ? widget.email
        : (user?.email ?? '');

    _originalPhone = user?.phone ?? '';
    avatarUrl = user?.avatarUrl;

    nameController = TextEditingController(text: _originalFirstName);
    lastNameController = TextEditingController(text: _originalLastName);
    emailController = TextEditingController(text: _originalEmail);
    phoneController = TextEditingController(text: _originalPhone);

    nameController.addListener(_checkIfChanged);
    lastNameController.addListener(_checkIfChanged);
    emailController.addListener(_checkIfChanged);
    phoneController.addListener(_checkIfChanged);
  }

  void _checkIfChanged() {
    final changed =
        nameController.text.trim() != (_originalFirstName ?? '') ||
        lastNameController.text.trim() != (_originalLastName ?? '') ||
        emailController.text.trim() != (_originalEmail ?? '') ||
        phoneController.text.replaceAll('-', '') !=
            (_originalPhone ?? '').replaceAll('-', '');

    setState(() {
      hasChanged = changed;
    });

    _validateForm();
  }

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    isFormValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    isFormValid.value = isValid;
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(userProvider);

    if (user == null || user.token == null || originalCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบใหม่')));
      return;
    }

    final Map<String, dynamic> updates = {};

    final currentFirstName = nameController.text.trim();
    final currentLastName = lastNameController.text.trim();
    final currentEmail = emailController.text.trim();
    final currentPhone = phoneController.text.replaceAll('-', '');

    if (currentFirstName != (_originalFirstName ?? '')) {
      updates['firstname'] = currentFirstName;
    }

    if (currentLastName != (_originalLastName ?? '')) {
      updates['lastname'] = currentLastName;
    }

    if (currentEmail != (_originalEmail ?? '')) {
      updates['email'] = currentEmail;
    }

    final originalPhone = (_originalPhone ?? '').replaceAll('-', '');
    if (currentPhone != originalPhone) {
      updates['phone'] = currentPhone;
    }

    if (updates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีการเปลี่ยนแปลงข้อมูล')),
      );
      return;
    }

    try {
      final success = await CustomerService().updateCustomer(
        user.token!,
        user.id,
        user.role,
        updates,
      );

      if (success) {
        await ref.read(userProvider.notifier).refreshUser();

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => SetupAddress(
              onSave: (data) async {
                final result = await ref
                    .read(addressProvider.notifier)
                    .createCustomerAddress(data);
                return result;
              },
            ),
          ),
        );

      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
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
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            children: [
              Header(header: "ตั้งค่าโปรไฟล์"),
              const SizedBox(height: 16),

              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : const AssetImage('assets/image/Technician.png')
                      as ImageProvider,
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

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 24,
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isFormValid,
                  builder: (context, valid, _) {
                    return PrimaryButton(
                      text: "ต่อไป",
                      onPressed: valid && hasChanged ? _saveProfile : null,
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
