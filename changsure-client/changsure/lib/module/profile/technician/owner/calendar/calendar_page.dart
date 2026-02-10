import 'package:changsure/core/header.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/module/profile/technician/owner/calendar/widget/technician_calendar.dart';
import 'package:changsure/module/profile/technician/owner/calendar/widget/today_work.dart';
import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int todayJobs = 3;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBGHover,
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        children: [
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              child: Column(
                children: [
                  Header(header: "ปฏิทินช่าง"),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 12,
                      left: 12,
                      top: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "สวัสดี คุณสมชาย รักชาติ",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              "วันนี้ คุณมีทั้งหมด",
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.colorTertiaryText,
                              ),
                            ),
                            const SizedBox(width: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBAE0FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "$todayJobs งาน",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const Spacer(), // ดันไปขวาสุด

                            if (todayJobs >= 3)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color:AppColors.colorError),
                                ),
                                child: const Text(
                                  "คิววันนี้เต็มแล้ว !",
                                  style: TextStyle(
                                    color: AppColors.colorError,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),

                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  TechnicianCalendar(),
                ],
              ),
            ),
          ),

          TodayWork(),
        ],
      ),
    );
  }
}
