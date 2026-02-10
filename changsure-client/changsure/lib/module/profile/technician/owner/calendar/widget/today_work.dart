import 'package:changsure/core/theme.dart';
import 'package:changsure/module/profile/technician/owner/calendar/widget/service_card.dart';
import 'package:flutter/material.dart';

import 'manage_today_work_sheet.dart';

class TodayWork extends StatefulWidget {
  const TodayWork({super.key});

  @override
  State<TodayWork> createState() => _TodayWorkState();
}

class _TodayWorkState extends State<TodayWork> {

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryBGHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "งานวันนี้",
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ManageTodayWorkSheet(),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.8),
                          AppColors.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.settings_outlined, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "จัดการงานวันนี้",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            ),
            SizedBox(height: 16,),
            ServiceCard()
          ],
        ),
      ),
    );
  }
}
