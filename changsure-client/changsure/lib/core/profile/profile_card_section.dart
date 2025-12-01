import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme.dart';

// MODELS
import 'package:changsure/models/customers/customer_profile.dart';
import '../../models/technicians/technician_profile.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class ProfileSection extends StatelessWidget {
  final dynamic profile; // รองรับทั้ง Customer / Technician
  final VoidCallback onEdit;
  final String? profileImageUrl; // override ถ้าต้องการส่งรูปจากภายนอก
  final String? phone; // override เบอร์

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

    // -----------------------------
    //   HANDLE CUSTOMER PROFILE
    // -----------------------------
    if (profile is CustomerProfile) {
      final p = profile as CustomerProfile;

      fullName = (p.fullName ?? "").trim().isNotEmpty ? p.fullName! : "-";

      email = (p.email ?? "").trim().isNotEmpty ? p.email!.trim() : "-";

      final rawPhone = phone ?? p.phone ?? "";
      phoneNumber = rawPhone.trim().isNotEmpty ? rawPhone.trim() : "-";

      avatarUrl = (profileImageUrl?.trim().isNotEmpty == true)
          ? profileImageUrl!.trim()
          : (p.avatarUrl ?? "");
    }
    // -----------------------------
    //   HANDLE TECHNICIAN PROFILE
    // -----------------------------
    else if (profile is TechnicianProfile) {
      final t = profile as TechnicianProfile;

      final composedName = "${t.firstname ?? ''} ${t.lastname ?? ''}".trim();
      fullName = composedName.isNotEmpty ? composedName : "-";

      email = (t.email ?? "").trim().isNotEmpty ? t.email! : "-";

      final rawPhone = phone ?? t.phone ?? "";
      phoneNumber = rawPhone.trim().isNotEmpty ? rawPhone.trim() : "-";

      avatarUrl = (profileImageUrl?.trim().isNotEmpty == true)
          ? profileImageUrl!.trim()
          : (t.avatarUrl ?? "");
    }

    // -----------------------------
    //   SELECT IMAGE PROVIDER
    // -----------------------------
    final ImageProvider avatarProvider = (avatarUrl.trim().isNotEmpty)
        ? NetworkImage(avatarUrl.trim())
        : const AssetImage("assets/image/Technician.png");

    // -----------------------------
    //   UI
    // -----------------------------
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: avatarProvider,
          ),

          const SizedBox(width: 16),

          // FULL NAME + EMAIL + PHONE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full name
                Text(
                  "คุณ $fullName",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // Email + Phone row
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

          // EDIT BUTTON
          IconButton(
            onPressed: onEdit,
            icon: SvgPicture.asset(
              "assets/icons/editIcon.svg",
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
