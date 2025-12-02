import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/theme.dart';
import '../../../state/bottom_bar_state.dart';
import '../../../state/profile_state.dart';

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // เอาเฉพาะตัวเลข
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // จำกัดให้ไม่เกิน 10 ตัว
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    // Format 099-999-9999
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) formatted += '-';
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isFormValid = ValueNotifier(false);
  final ValueNotifier<bool> hasChanged = ValueNotifier(false);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  late Map<String, String> initialData;
  void _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    isFormValid.value = isValid;

    // เช็คว่ามีการแก้ไขข้อมูลหรือไม่
    hasChanged.value = (
        nameController.text != initialData["firstname"] ||
            lastNameController.text != initialData["lastname"] ||
            emailController.text != initialData["email"] ||
            phoneController.text != initialData["phone"]
    );
  }

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (profileState.isTechnician) {
        final p = profileState.technicianProfile;

        nameController.text = p?.firstname ?? "";
        lastNameController.text = p?.lastname ?? "";
        emailController.text = p?.email ?? "";
        phoneController.text = p?.phone ?? "";
      } else {
        final p = profileState.customerProfile;

        nameController.text = p?.firstname ?? "";
        lastNameController.text = p?.lastname ?? "";
        emailController.text = p?.email ?? "";
        phoneController.text = p?.phone ?? "";
      }
    });


  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
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
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: (_) => _validateForm(),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.colorStroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.colorStroke),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.colorError,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primaryBorder,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.colorError,
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(
                color: AppColors.colorError,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileState>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Header(header: "แก้ไขโปรไฟล์"),
            const SizedBox(height: 16),

            // Avatar
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/image/Technician.png'),
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

            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildTextField(
                    "ชื่อ",
                    nameController,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "กรุณากรอกชื่อ";
                      if (v.length < 2) return "ชื่อต้องมีอย่างน้อย 2 ตัวอักษร";
                      return null;
                    },
                  ),

                  _buildTextField(
                    "นามสกุล",
                    lastNameController,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "กรุณากรอกนามสกุล";
                      return null;
                    },
                  ),

                  _buildTextField(
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

                  _buildTextField(
                    "เบอร์โทร",
                    phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_PhoneNumberFormatter()],
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: ValueListenableBuilder<bool>(
                valueListenable: isFormValid,
                builder: (context, valid, _) {
                  return PrimaryButton(
                    text: profileState.loading
                        ? "กำลังบันทึก..."
                        : "บันทึกการแก้ไข",

                    // ปุ่มกดได้เฉพาะเมื่อฟอร์ม valid และไม่โหลด
                    onPressed: (!valid || profileState.loading)
                        ? () async {
                            final success = await profileState.updateProfile(
                              firstname: nameController.text,
                              lastname: lastNameController.text,
                              email: emailController.text,
                              phone: phoneController.text,
                            );

                            if (success && context.mounted) {
                              Provider.of<BottomBarState>(
                                context,
                                listen: false,
                              ).closeSubPage();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "เกิดข้อผิดพลาด: ${profileState.error}",
                                  ),
                                ),
                              );
                            }
                          }
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
