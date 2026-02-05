import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class TrackingSection extends StatelessWidget {
  const TrackingSection({super.key});

  Widget _buildStatusTag(String text, Color bgColor, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusTag(
          "กำลังดำเนินการ",
          AppColors.primary.withOpacity(0.1),
          AppColors.primary,
          AppColors.primary,
        ),
        // _buildStatusTag(
        //   "รอช่างรับงาน",
        //   AppColors.gold01,
        //   AppColors.gold03,
        //   AppColors.gold06,
        // ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("หมายเลขบริการ"),
            Text("3456789098666"),
          ],
        ),

       
        const SizedBox(height: 12),

        Row(
          children: [
            _buildStep(true),
            _buildLine(true),
            _buildStep(true),
            _buildLine(false),
            _buildStep(false),
            _buildLine(false),
            _buildStep(false),
          ],
        ),
        const SizedBox(height: 6),

        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("จองบริการ"),
            Text("รอช่างรับงาน"),
            Text("ช่างกำลังดำเนินการ"),
            Text("เสร็จสิ้น"),
          ],
        ),
      ],
    );
  }

  Widget _buildStep(bool active) {
    return CircleAvatar(
      radius: 6,
      backgroundColor: active ? AppColors.primary : Colors.grey.shade300,
    );
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }
}