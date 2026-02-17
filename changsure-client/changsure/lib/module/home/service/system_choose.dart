import 'package:changsure/module/profile/technician/owner/activities/shared/constants/activity_constants.dart';
import 'package:changsure/module/profile/technician/public/pages/public_technician_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/header.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/button/secondary_button.dart';
import '../../../core/theme.dart';
import '../../../data/models/master_data_models.dart';
import '../../../state/master_data_provider.dart';
import '../../profile/technician/owner/pages/my_profile_page.dart';
import '../booking/booking_page.dart';

class SystemChoose extends ConsumerStatefulWidget {
  final String serviceName;
  final int category;
  final int maxPrice;
  final int serviceId;
  final int? provinceId;
  final ServiceModel data;

  const SystemChoose({
    super.key,
    required this.serviceName,
    required this.category,
    required this.maxPrice,
    required this.serviceId,
    required this.provinceId,
    required this.data,
  });

  @override
  ConsumerState<SystemChoose> createState() => _SystemChooseState();
}

class _SystemChooseState extends ConsumerState<SystemChoose> {

  Widget _buildTag(String iconUrl, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            iconUrl,
            width: 14,
            height: 14,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 14),
          ),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(String shortName) {
    final categoryKey = _toActivityCategoryKey(shortName);
    final colors = ActivityConstants.getColors(categoryKey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Text(
        shortName, // โชว์แบบสั้นเหมือนเดิม
        style: TextStyle(color: colors.text, fontSize: 12),
      ),
    );
  }

  String _getDisplayCategoryName(String categoryName) {
    final map = {
      "งานทาสี": "ทาสี",
      "งานประปา": "ประปา",
      "งานไฟฟ้า": "ไฟฟ้า",
      "งานเครื่องใช้ไฟฟ้า": "เครื่องใช้ไฟฟ้า",
    };

    return map[categoryName] ?? categoryName;
  }

  String _toActivityCategoryKey(String shortName) {
    const map = {
      "ทาสี": "งานทาสี",
      "การประปา": "งานประปา",
      "ประปา": "งานประปา",
      "การไฟฟ้า": "งานไฟฟ้า",
      "ไฟฟ้า": "งานไฟฟ้า",
      "เครื่องใช้ไฟฟ้า": "งานเครื่องใช้ไฟฟ้า",
    };

    return map[shortName] ?? shortName;
  }

  @override
  Widget build(BuildContext context) {
    final asyncTechs = ref.watch(
      autoSelectTechnicianProvider(
        AutoSelectTechnicianQuery(
          serviceId: widget.serviceId,
          provinceId: widget.provinceId!,
          maxPrice: widget.maxPrice,
        ),
      ),
    );

    print(asyncTechs);
    print(widget.serviceId);
    print(widget.provinceId!);
    print(widget.maxPrice);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: asyncTechs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("เกิดข้อผิดพลาด: $e")),
          data: (tech) {
            if (tech == null) {
              return ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 6,
                ),
                children: const [
                  Center(
                    child: Text(
                      "ยังไม่มีช่างที่เหมาะสม",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              children: [
                Header(
                  header: "ระบบเลือกช่างอัตโนมัติ",
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
                // ===== SERVICE NAME =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.serviceName,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "เราจะแนะนำช่างที่เหมาะสมที่สุดตามงานของคุณ",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.colorTertiaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    children: [
                      _TechnicianCard(
                        tech: tech,
                        buildTag: _buildTag,
                        serviceData: widget.data,
                        provinceId: widget.provinceId,
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _buildCategoryTag(
                          _getDisplayCategoryName(tech.categoryName),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  final Technician tech;
  final Widget Function(String, String) buildTag;
  final ServiceModel serviceData;
  final int? provinceId;

  const _TechnicianCard({
    required this.tech,
    required this.buildTag,
    required this.serviceData,
    required this.provinceId
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBG,
        border: Border.all(color: AppColors.colorStroke),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 12,
                color: AppColors.colorTertiaryText,
              ),
              const SizedBox(width: 3),
              Text(
                "${tech.distanceKm.toStringAsFixed(1)} km",
                style: const TextStyle(
                  color: AppColors.colorTertiaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          CircleAvatar(
            radius: 40,
            backgroundImage:
                tech.avatarUrl != null && tech.avatarUrl!.isNotEmpty
                ? NetworkImage(tech.avatarUrl!)
                : AssetImage('assets/image/Technician.png') as ImageProvider,
          ),
          SizedBox(height: 8),
          Text(
            "คุณ ${tech.firstname} ${tech.lastname}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    tech.priceMax > tech.priceMin
                        ? "฿${tech.priceMin} - ${tech.priceMax}"
                        : "฿${tech.priceMin}",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rate_rounded,
                color: Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                tech.ratingAvg?.toString() ?? "0",
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 3),
              const Text(
                " / 5",
                style: TextStyle(
                  color: AppColors.colorTertiaryText,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "|",
                style: TextStyle(color: AppColors.colorStroke, fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                "จำนวนงานที่รับ: ",
                style: const TextStyle(
                  color: AppColors.colorTertiaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: tech.badges
                .where((b) => b.isActive)
                .map((b) => buildTag(b.iconUrl, b.name))
                .toList(),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: "ดูโปรไฟล์",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PublicTechnicianProfilePage(technicianId: tech.id),
                      ),
                    );
                  },
                  padding: EdgeInsets.symmetric(vertical: 6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: "จองช่าง",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            (BookingPage(data: serviceData, technician: tech, provinceId: provinceId,)),
                      ),
                    );
                  },
                  padding: EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
