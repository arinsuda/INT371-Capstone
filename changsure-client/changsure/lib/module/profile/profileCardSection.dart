import 'package:flutter/material.dart';
import '../../core/theme.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class ProfileSection extends StatelessWidget {
  final String profileImage;
  final String fullName;
  final String email;
  final String phone;
  final VoidCallback onEdit;

  const ProfileSection({
    super.key,
    required this.profileImage,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 18,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // รูปโปรไฟล์
          CircleAvatar(radius: 30, backgroundImage: AssetImage(profileImage)),
          SizedBox(width: toLogicalPx(context, 16)),

          // ชื่อ อีเมล เบอร์
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่อเต็ม
                Text(
                  "คุณ ${fullName}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // แถวเดียว: Email + Phone
                Row(
                  children: [
                    // Email
                    Icon(Icons.email, size: 14, color: const Color(0xFF9B9B9B) ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF545454),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: toLogicalPx(context, 16)),

                    // Phone
                    Icon(Icons.phone, size: 14, color: const Color(0xFF9B9B9B)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        phone,
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF545454),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ปุ่ม Edit
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_square, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
