import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme.dart';
import '../../models/technicians/technician_profile.dart';

import '../../models/customers/customer_profile.dart';
import '../../models/technicians/technician_profile.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class ProfileSection extends StatelessWidget {
  final dynamic profile;
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
    String fullName = "-";
    String email = "-";
    String phoneNumber = "-";
    String avatarUrl = "";

    if (profile is CustomerProfile) {
      final p = profile as CustomerProfile;

      fullName = p.fullName;

      final safeEmail = p.email?.trim() ?? "";
      email = safeEmail.isNotEmpty ? safeEmail : "-";

      final rawPhone = phone ?? p.phone ?? "";
      final safePhone = rawPhone.trim();
      phoneNumber = safePhone.isNotEmpty ? safePhone : "-";

      final safeAvatar = (profileImageUrl?.trim() ?? "").isNotEmpty
          ? profileImageUrl!.trim()
          : (p.avatarUrl?.trim() ?? "");

      avatarUrl = safeAvatar.isNotEmpty ? safeAvatar : "";
    } else if (profile is TechnicianProfile) {
      final t = profile;

      fullName = "${t.firstname} ${t.lastname}".trim().isNotEmpty
          ? "${t.firstname} ${t.lastname}"
          : "-";

      email = (t.email.trim().isNotEmpty) ? t.email : "-";

      phoneNumber = ((phone ?? t.phone).trim().isNotEmpty)
          ? (phone ?? t.phone)
          : "-";

      avatarUrl = (profileImageUrl?.trim().isNotEmpty == true)
          ? profileImageUrl!
          : (t.avatarUrl);
    }

    final ImageProvider avatarProvider = avatarUrl.isNotEmpty
        ? NetworkImage(avatarUrl)
        : const AssetImage("assets/image/Technician.png");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: avatarProvider,
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
                        phoneNumber,
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
