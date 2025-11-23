import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/theme.dart';
import '../../../../models/profile.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class ProfileSection extends StatelessWidget {
  final Profile profile;
  final VoidCallback onEdit;

  final String? profileImageUrl;
  final String? phone;

  const ProfileSection({
    super.key,
    required this.profile,
    required this.onEdit,
    this.profileImageUrl,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = profile.fullName;
    final email = profile.email;
    final showPhone = (phone != null && phone!.trim().isNotEmpty)
        ? phone!
        : "-";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade300,
            backgroundImage:
                (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                ? NetworkImage(profileImageUrl!)
                : const AssetImage("assets/image/default_profile.png")
                      as ImageProvider,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "คุณ $fullName",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.email, size: 14, color: Color(0xFF9B9B9B)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        email,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF545454),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    SizedBox(width: toLogicalPx(context, 16)),

                    const Icon(Icons.phone, size: 14, color: Color(0xFF9B9B9B)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        showPhone,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF545454),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: onEdit,
            icon: SvgPicture.asset(
              'assets/icons/editIcon.svg',
              width: 24,
              height: 24,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
