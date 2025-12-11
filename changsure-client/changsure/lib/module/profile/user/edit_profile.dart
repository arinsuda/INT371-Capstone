import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/theme.dart';
import '../../../core/profile/editProfile/phone_formatter.dart';
import '../../../core/profile/editProfile/text_field.dart';


class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isFormValid = ValueNotifier(false);

  final TextEditingController nameController = TextEditingController(
    text: 'สมศักดิ์',
  );
  final TextEditingController lastNameController = TextEditingController(
    text: 'หนวดเยิ้ม',
  );
  final TextEditingController emailController = TextEditingController(
    text: 'somsuk@gmail.com',
  );
  final TextEditingController phoneController = TextEditingController(
    text: '099-999-9999',
  );

  void _validateForm() {
    // ถ้า formKey ปกติ → validate ทั้งฟอร์ม
    final isValid = _formKey.currentState?.validate() ?? false;
    isFormValid.value = isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            children: [
              // ---------- Header ----------
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                      validator: (v) {
                        if (v == null || v.isEmpty) return "กรุณากรอกนามสกุล";
                        return null;
                      },
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
                  vertical: 0,
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isFormValid,
                  builder: (context, valid, _) {
                    return PrimaryButton(
                      text: "บันทึกการแก้ไข",
                      onPressed: valid
                          ? () {
                              // SAVE HERE
                            }
                          : null, // <-- disable button when invalid
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
