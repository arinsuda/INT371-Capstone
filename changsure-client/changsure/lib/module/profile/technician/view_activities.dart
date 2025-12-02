import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../../core/profile/technician_card.dart';
import '../../../core/theme.dart';
import '../../../mockDB/activities.dart';
import '../../../state/bottom_bar_state.dart';
import 'activities/post_activity.dart';

class ViewActivities extends StatefulWidget {
  const ViewActivities({super.key});

  @override
  State<ViewActivities> createState() => _ViewActivitiesState();
}

class _ViewActivitiesState extends State<ViewActivities> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
            Padding(
              padding: const EdgeInsets.all(6),
              child: GridView.builder(
                shrinkWrap: true,
                // ให้ GridView ขยายตามจำนวน item
                physics: const NeverScrollableScrollPhysics(),
                // ป้องกัน scroll ซ้อน
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 คอลัมน์
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: mockActivities.length,
                itemBuilder: (context, index) {
                  final activity = mockActivities[index];
                  return TechnicianCard(
                    id: activity.id,
                    serviceCategoryName: activity.serviceCategoryName,
                    description: activity.description,
                    images: activity.images,
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