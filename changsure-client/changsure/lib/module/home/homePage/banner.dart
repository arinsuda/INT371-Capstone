import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../state/province_state.dart';
import '../../../state/profile_state.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<ProvinceState>().loadProvinces();
      context.read<ProfileState>().loadProfile();
    });
  }

  void _openProvinceSelector() {
    final profileState = context.read<ProfileState>();
    final provinceState = context.read<ProvinceState>();

    if (!profileState.isTechnician) return;

    List<int> selectedIds = List.from(
      profileState.technicianProfile?.provinces.map((p) => p.id).toList() ?? [],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (provinceState.loading || profileState.loading) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final provinces = provinceState.provinces ?? [];

            final sortedProvinces = [...provinces];

            sortedProvinces.sort((a, b) {
              final aSel = selectedIds.contains(a.id);
              final bSel = selectedIds.contains(b.id);

              if (aSel && !bSel) return -1;
              if (!aSel && bSel) return 1;

              if (aSel && bSel) {
                return a.id.compareTo(b.id);
              }

              return (a.nameTh ?? "").compareTo(b.nameTh ?? "");
            });

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  const Text(
                    "พื้นที่ให้บริการของคุณ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.builder(
                      itemCount: sortedProvinces.length,
                      itemBuilder: (context, index) {
                        final p = sortedProvinces[index];
                        final bool isChecked = selectedIds.contains(p.id);

                        return CheckboxListTile(
                          title: Text(
                            p.nameTh ?? "-",
                            style: const TextStyle(fontSize: 14),
                          ),
                          value: isChecked,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            if (val == true) {
                              selectedIds.add(p.id);
                            } else {
                              selectedIds.remove(p.id);
                            }

                            setModalState(() {});
                          },
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () async {
                        final ok = await profileState.updateTechnicianProvinces(
                          selectedIds,
                        );

                        if (ok && mounted) Navigator.pop(context);
                      },
                      child: const Text(
                        "บันทึกพื้นที่ให้บริการ",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileState>();

    String displayProvince = "เลือกพื้นที่บริการ";

    if (profileState.isTechnician &&
        profileState.technicianProfile?.provinces.isNotEmpty == true) {
      displayProvince =
          profileState.technicianProfile!.provinces.first.nameTh ??
          displayProvince;
    }

    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          Container(
            height: 270,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/image/banner.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(
            height: 270,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFB7CFFF).withOpacity(0.1),
                  AppColors.primary.withOpacity(0.1),
                  const Color(0xFF001F9F).withOpacity(0.2),
                  const Color(0xFF020927).withOpacity(0.5),
                ],
              ),
            ),
          ),

          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: _openProvinceSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: Color(0xFF3071C7),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        displayProvince,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3071C7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF3071C7),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 240,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.colorStroke),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("ค้นหา...", style: TextStyle(color: Colors.grey)),
                  Icon(Icons.search, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
