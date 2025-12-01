import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../core/profile/technician_card.dart';
import '../../../core/theme.dart';
import '../../../state/bottom_bar_state.dart';
import '../../../state/ativity_state.dart';
import 'activities/post_activity.dart';

class ViewActivities extends StatefulWidget {
  const ViewActivities({super.key});

  @override
  State<ViewActivities> createState() => _ViewActivitiesState();
}

class _ViewActivitiesState extends State<ViewActivities> {
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TechnicianWorkState>().loadWorks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workState = context.watch<TechnicianWorkState>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Header(header: "ลงผลงาน"),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) {
                    setState(() => _isPressed = false);
                    Provider.of<BottomBarState>(
                      context,
                      listen: false,
                    ).setSubPage(const PostActivity());
                  },
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _isPressed
                            ? [
                                AppColors.secondary.withOpacity(0.8),
                                AppColors.secondary,
                              ]
                            : [
                                AppColors.primary.withOpacity(0.8),
                                AppColors.primary,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/addActivityIcon.svg',
                          height: 16,
                          width: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "เพิ่มผลงาน",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (workState.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (workState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "เกิดข้อผิดพลาด: ${workState.errorMessage}",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

            if (!workState.isLoading &&
                workState.errorMessage == null &&
                workState.works.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    "ยังไม่มีผลงานที่บันทึก",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.colorTertiaryText,
                    ),
                  ),
                ),
              ),

            if (workState.works.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(6),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: workState.works.length,
                  itemBuilder: (context, index) {
                    final w = workState.works[index];

                    return TechnicianCard(
                      id: w.id,
                      serviceCategoryName: w.serviceName ?? "-",
                      description: w.description ?? "",
                      images: w.images.map((img) => img.imageUrl).toList(),
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
