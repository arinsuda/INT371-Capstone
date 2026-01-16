// changsure/lib/module/profile/technician/activities/widgets/activity_action_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:changsure/core/theme.dart';

/// Action menu button for activity detail (Edit/Delete)
class ActivityActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ActivityActionMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      elevation: 4,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SvgPicture.asset(
        'assets/icons/optionIcon.svg',
        height: 20,
        width: 20,
      ),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        _buildMenuItem('edit', Icons.create_rounded, "แก้ไขโพสต์"),
        _buildMenuItem('delete', Icons.delete, "ลบโพสต์"),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Center(
              child: Icon(icon, size: 20, color: AppColors.colorTertiaryText),
            ),
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
