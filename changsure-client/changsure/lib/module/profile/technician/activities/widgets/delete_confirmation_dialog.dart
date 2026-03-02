// changsure/lib/module/profile/technician/activities/widgets/delete_confirmation_dialog.dart

import 'package:flutter/material.dart';
import 'package:changsure/core/button/tertiary_button.dart';

/// Delete confirmation dialog for activity
class DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String? title;
  final String? message;

  const DeleteConfirmationDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    this.title,
    this.message,
  });

  /// Show dialog helper
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onConfirm,
    String? title,
    String? message,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => DeleteConfirmationDialog(
        onConfirm: onConfirm,
        onCancel: () => Navigator.of(context).pop(),
        title: title,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title ?? "ลบผลงาน",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message ??
                  "คุณแน่ใจหรือไม่ว่าต้องการลบผลงานนี้ออกจากหน้าโปรไฟล์ช่างของคุณ? "
                      "ผลงานดังกล่าวจะถูกลบออกจากโปรไฟล์ของคุณอย่างถาวร",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TertiaryButton(
                    text: "ยกเลิก",
                    onPressed: onCancel,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    fontSize: 14,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF5222D)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: const Color(0xFFF5222D),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onConfirm,
                    child: const Text(
                      "ลบ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
