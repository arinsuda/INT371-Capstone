import 'package:flutter/material.dart';
import 'post_activity_category_dropdown.dart';

class PostActivityProfileHeader extends StatelessWidget {
  const PostActivityProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/image/Technician.png'),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "คุณ สมชาย รักชาติ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                PostActivityCategoryDropdown(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
