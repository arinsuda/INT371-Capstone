import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme.dart';
import '../../../../state/profile_state.dart';
import 'activity_section.dart';
import 'technician_badge.dart';
import 'service.dart';

class ViewProfileContent extends StatelessWidget {
  const ViewProfileContent({super.key});

  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );

    if (file == null) return;

    await context.read<ProfileState>().changeAvatar(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileState>(
      builder: (context, state, child) {
        final t = state.technicianProfile;

        // เข้าหน้าโปรไฟล์ครั้งแรก → โหลดข้อมูล → loading
        if (state.loading && t == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // ถ้าโหลดเสร็จแต่ข้อมูลยัง null → ป้องกันไม่ให้ค้าง
        if (t == null) {
          return const Center(child: Text("ไม่พบข้อมูลโปรไฟล์ช่าง"));
        }

        // ใช้ข้อมูลต่อไป

        final avatarUrl = (t.avatarUrl?.isNotEmpty == true)
            ? t.avatarUrl!
            : "assets/image/Technician.png";

        final fullName =
            "${t.firstname ?? ''} ${t.lastname ?? ''}".trim().isNotEmpty
            ? "${t.firstname ?? ''} ${t.lastname ?? ''}"
            : "-";

        final email = (t.email ?? "").isNotEmpty ? t.email! : "-";
        final phone = (t.phone ?? "").isNotEmpty ? t.phone! : "-";
        final aboutText = (t.bio ?? "").isNotEmpty
            ? t.bio!
            : "ยังไม่มีข้อมูลแนะนำตัว";

        final totalJobs = t.serviceSummary.isNotEmpty
            ? t.serviceSummary.fold<int>(
                0,
                (sum, e) => sum + ((e.total ?? 0).toInt()),
              )
            : 0;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: avatarUrl.startsWith("http")
                              ? NetworkImage(avatarUrl)
                              : AssetImage(avatarUrl) as ImageProvider,
                        ),

                        // Positioned(
                        //   bottom: 0,
                        //   right: 0,
                        //   child:
                        //   GestureDetector(
                        //     onTap: () => _pickAvatar(context),
                        //     child: Container(
                        //       decoration: const BoxDecoration(
                        //         shape: BoxShape.circle,
                        //         color: Colors.white,
                        //       ),
                        //       padding: const EdgeInsets.all(4),
                        //       child: const CircleAvatar(
                        //         radius: 12,
                        //         backgroundColor: Color(0xFFE8E8E8),
                        //         child: Icon(
                        //           Icons.camera_alt,
                        //           color: Colors.black,
                        //           size: 14,
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "คุณ $fullName",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (t.isVerified == true)
                            Image.asset(
                              'assets/icons/verify.png',
                              width: 24,
                              height: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.email,
                            size: 14,
                            color: Color(0xFF9B9B9B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF545454),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: Color(0xFF9B9B9B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF545454),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/bag_work.svg',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'จำนวนงานที่รับ: $totalJobs',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TechnicianBadge(badges: t.badges),
                  ),

                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "เกี่ยวกับ",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      aboutText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.colorTertiaryText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ServiceTag(services: t.services),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            const ActivitySection(),
          ],
        );
      },
    );
  }
}
