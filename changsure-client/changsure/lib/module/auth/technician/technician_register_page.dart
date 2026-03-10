import 'package:changsure/core/header.dart';
import 'package:changsure/module/auth/technician/setup_technician_profile.dart';
import 'package:changsure/module/auth/technician/technician_register_step_provider.dart';
import 'package:changsure/module/auth/technician/verify_page.dart';
import 'package:changsure/module/auth/technician/work_type_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';

class TechnicianRegisterPage extends ConsumerStatefulWidget {
  const TechnicianRegisterPage({super.key});

  @override
  ConsumerState<TechnicianRegisterPage> createState() =>
      _TechnicianRegisterPageState();
}

class _TechnicianRegisterPageState
    extends ConsumerState<TechnicianRegisterPage> {
  Widget _buildCustomStepper(int step) {
    final List<String> labels = ["ข้อมูลส่วนตัว", "ประเภทงาน", "ยืนยันตัวตน"];

    return Row(
      children: List.generate(labels.length, (index) {
        bool isCompleted = index < step;
        bool isCurrent = index == step - 1;
        bool isLast = index == labels.length - 1;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      color: index == 0
                          ? Colors.transparent
                          : (index <= step - 1
                                ? Color(0xFF1677FF)
                                : Colors.grey.shade200),
                    ),
                  ),

                  Icon(
                    Icons.circle,
                    size: isCurrent ? 20 : 18,
                    color: (index <= step - 1)
                        ? Color(0xFF1677FF)
                        : Colors.grey.shade400,
                  ),

                  Expanded(
                    child: Container(
                      height: 4,
                      color: isLast
                          ? Colors.transparent
                          : (index < step - 1
                                ? Color(0xFF1677FF)
                                : Colors.grey.shade200),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 30,
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: (index <= step - 1)
                        ? Colors.black
                        : AppColors.colorTertiaryText,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 1:
        return const SetupTechnicianProfile();

      case 2:
        return const WorkTypeListPage();

      case 3:
        return const VerifyPage();

      default:
        return const SetupTechnicianProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(technicianRegisterStepProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 12, vertical: 16),
          children: [
            Header(
              header: "ลงทะเบียนช่าง",
              fontSize: 26,
              color: AppColors.primaryText,
            ),

            SizedBox(height: 32),

            _buildCustomStepper(currentStep),

            SizedBox(height: 24),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 6),
              child: _buildStepContent(currentStep),
            ),
          ],
        ),
      ),
    );
  }
}
