import 'package:changsure/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const NotificationItem({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('HH:mm').format(item.createdAt);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        color: item.isRead ? Colors.white : AppColors.primaryBGHover,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              "assets/image/Logo_ChangSure_Transparents.PNG",
              width: 60,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 280,
                    child: Text(
                      item.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.colorTertiaryText,
                        height: 1.4,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: AppColors.primaryBorder),
                  ),
                ],
              ),
            ),

            if (!item.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4, right: 10),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
