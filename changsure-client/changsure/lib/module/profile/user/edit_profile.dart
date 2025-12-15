import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/button/primary_button.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

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
    final isValid = _formKey.currentState?.validate() ?? false;
    isFormValid.value = isValid;
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
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
                      onPressed: valid
                          ? () {
                              // Save Logic
                              print("บันทึกข้อมูล: ${nameController.text}");
                            }
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
