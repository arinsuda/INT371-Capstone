import 'package:changsure/core/theme.dart';
import 'package:changsure/module/auth/technician/technician_start_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../../core/button/primary_button.dart';
import '../../data/models/users/users_model.dart';
import '../../data/services/auth_service.dart';
import '../../state/master_data_provider.dart';
import '../../state/user_provider.dart';
import 'customer/setup_profile_page.dart';

class ChooseRolePage extends ConsumerStatefulWidget {
  final String email;
  final String password;
  final String confirmPassword;
  final String? accessToken;
  final String? refreshToken;

  const ChooseRolePage({
    super.key,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.refreshToken,
    this.accessToken,
  });

  @override
  ConsumerState<ChooseRolePage> createState() => _ChooseRolePageState();
}

class _ChooseRolePageState extends ConsumerState<ChooseRolePage> {
  int selectedIndex = -1;

  final List<String> options = ["ช่าง", "ผู้รับบริการ"];

  bool get canConfirm => selectedIndex != -1;

  String get selectedRole {
    if (selectedIndex == 0) return "technician";
    return "customer";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset("assets/image/choose_role_banner.png"),
                Positioned(
                  top: 16,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "ยินดีต้อนรับสู่ ช่างชัวร์",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "เลือกบทบาทของคุณ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.colorTertiaryText,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedIndex == index;

                  final iconPath = index == 0
                      ? "assets/icons/technician.svg"
                      : "assets/icons/customer.svg";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    // 👈 ระยะห่างระหว่างกล่อง
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryBGHover
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : const Color(0xFFD6D6D6),
                                  width: 1,
                                ),
                              ),

                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  /// ✅ SVG Icon
                                  SvgPicture.asset(
                                    iconPath,
                                    width: 28,
                                    height: 28,
                                  ),

                                  const SizedBox(width: 16),

                                  /// Text
                                  Expanded(
                                    child: Text(
                                      options[index],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F53BA),
                                      ),
                                    ),
                                  ),

                                  Radio<int>(
                                    value: index,
                                    groupValue: selectedIndex,
                                    activeColor: const Color(0xFF0F53BA),
                                    onChanged: (val) {
                                      setState(() {
                                        selectedIndex = val!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 8,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF0F53BA),
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
              child: PrimaryButton(
                text: "ยืนยัน",
                onPressed: canConfirm
                    ? () async {
                  try {
                    /// 1️⃣ REGISTER
                    final registerModel = RegisterModel(
                      email: widget.email,
                      password: widget.password,
                      confirmPassword: widget.confirmPassword,
                      role: selectedRole,
                    );

                    await ref
                        .read(registerProvider.notifier)
                        .register(registerModel);

                    final registerState = ref.read(registerProvider);

                    if (registerState.hasError) {
                      debugPrint("REGISTER API ERROR: ${registerState.error}");
                    }

                    if (!(registerState.hasValue && registerState.value != null)) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('สมัครสมาชิกไม่สำเร็จ'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    /// 2️⃣ LOGIN อัตโนมัติ
                    final authService = AuthService();
                    final result = await authService.login(
                      widget.email,
                      widget.password,
                    );

                    if (result == null) {
                      // error
                      return;
                    }


                    final token = result['access_token'] as String;
                    final userId = result['user_id'] as int;
                    final roleStr = (result['role'] as String).toUpperCase();

                    UserModel user;

                    if (roleStr == 'TECHNICIAN') {
                      final techProfile =
                      await authService.getTechnicianProfile(token, userId);

                      user = UserModel(
                        id: userId,
                        email: widget.email,
                        token: token,
                        role: UserRole.technician,
                        technicianProfile: techProfile,
                      );
                    } else {
                      final customerProfile =
                      await authService.getCustomerProfile(token, userId);

                      user = UserModel(
                        id: userId,
                        email: widget.email,
                        token: token,
                        role: UserRole.customer,
                        customerProfile: customerProfile,
                      );
                    }

                    await ref.read(userProvider.notifier).login(
                      user,
                      result['refresh_token'] as String,
                    );

                    /// 3️⃣ NAVIGATE ตาม role ที่เลือก
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => selectedRole == "technician"
                            ? TechnicianStartPage(email: widget.email)
                            : SetupProfilePage(email: widget.email),
                      ),
                    );
                  } catch (e, stack) {
                    debugPrint("REGISTER ERROR: $e");
                    debugPrintStack(stackTrace: stack);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('เกิดข้อผิดพลาด: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
                    : null,
              ),
            ),
            // Padding(
            //   padding: EdgeInsetsGeometry.symmetric(
            //     horizontal: 24,
            //     vertical: 16,
            //   ),
            //   child: Align(
            //     alignment: Alignment.center,
            //     child: Text(
            //       "ข้ามขั้นตอน",
            //       style: TextStyle(
            //         color: Color(0xFF3071C7),
            //         fontSize: 16,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
