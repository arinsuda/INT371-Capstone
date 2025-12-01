import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/button/primary_button.dart';
import '../../../core/theme.dart';
import '../../../state/profile_state.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

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
                  _buildTextField("ชื่อ", nameController),
                  _buildTextField("นามสกุล", lastNameController),
                  _buildTextField("อีเมล", emailController),
                  _buildTextField("เบอร์โทร", phoneController),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: PrimaryButton(
                text: profileState.loading
                    ? "กำลังบันทึก..."
                    : "บันทึกการแก้ไข",
                onPressed: profileState.loading
                    ? null
                    : () async {
                        final success = await profileState.updateProfile(
                          firstname: nameController.text,
                          lastname: lastNameController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                        );

                        if (success && mounted) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "เกิดข้อผิดพลาด: ${profileState.error}",
                              ),
                            ),
                          );
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTextField(String label, TextEditingController controller) {
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
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.colorStroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryBorder,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
