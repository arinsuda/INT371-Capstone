import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:changsure/core/button/primaryButton.dart';
import 'package:changsure/core/theme.dart';
import 'package:provider/provider.dart';
import '../../../state/province_state.dart';
import '../../../state/profile_state.dart';
import 'package:flutter/services.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  Map<String, bool> _selectedProvinces = {};
  String _searchText = '';

  bool hasChanged = false;

  void _checkChanged() {
    setState(() => hasChanged = true);
  }

  ImageProvider _buildProfileImage(BuildContext context) {
    final profile = context.read<ProfileState>();
    final tech = profile.technicianProfile;

    // 1) ไม่มีข้อมูลโปรไฟล์เลย → ใช้ default
    if (tech == null || tech.avatarUrl == null || tech.avatarUrl!.isEmpty) {
      return const AssetImage('assets/image/Technician.png');
    }

    // 2) มีรูป → โหลดตาม URL
    try {
      return NetworkImage(tech.avatarUrl!);
    } catch (_) {
      // 3) โหลดรูปไม่ได้ → ใช้ fallback
      return const AssetImage('assets/image/Technician.png');
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final profile = context.read<ProfileState>();
      final provinces = context.read<ProvinceState>();

      await profile.loadProfile();
      await provinces.loadProvinces();

      final tech = profile.technicianProfile;
      if (tech != null) {
        nameController.text = tech.firstname;
        lastNameController.text = tech.lastname;
        emailController.text = tech.email;
        phoneController.text = tech.phone;
        aboutController.text = tech.bio;

        for (var p in provinces.provinces ?? []) {
          _selectedProvinces[p.nameTh ?? ""] = tech.provinces.any(
            (tp) => tp.id == p.id,
          );
        }
      }

      setState(() {});
    });

    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>();
    final provinceState = context.watch<ProvinceState>();

    if (profile.loading || provinceState.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Header(header: "แก้ไขโปรไฟล์"),
            const SizedBox(height: 16),

            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _buildProfileImage(context),
                    onBackgroundImageError: (_, __) {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildTextField("ชื่อ", nameController),
            _buildTextField("นามสกุล", lastNameController),
            _buildTextField("อีเมล", emailController),
            _buildTextField("เบอร์โทร", phoneController),
            _buildTextArea("เกี่ยวกับ", aboutController),

            const SizedBox(height: 12),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "จังหวัดที่รับบริการ",
                style: TextStyle(
                  color: AppColors.colorTertiaryText,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildProvinceSearchBar(),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildProvinceCheckboxList(),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: PrimaryButton(
                text: hasChanged ? "บันทึกการแก้ไข" : "ไม่มีการเปลี่ยนแปลง",
                onPressed: !hasChanged
                    ? null
                    : () async {
                        final profile = context.read<ProfileState>();
                        final provinceData = context.read<ProvinceState>();

                        final selectedIds = _selectedProvinces.entries
                            .where((e) => e.value)
                            .map((e) {
                              final match = provinceData.provinces!.firstWhere(
                                (p) => p.nameTh == e.key,
                              );
                              return match.id;
                            })
                            .toList();

                        await profile.updateProfile(
                          firstname: nameController.text.trim(),
                          lastname: lastNameController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                          bio: aboutController.text.trim(),
                        );

                        await profile.updateTechnicianProvinces(selectedIds);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("บันทึกสำเร็จ")),
                          );
                          Navigator.pop(context);
                        }
                      },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.colorTertiaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: (_) => _checkChanged(),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.colorStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primaryBorder,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.colorTertiaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: 5,
            onChanged: (_) => _checkChanged(),
            decoration: InputDecoration(
              hintText: 'เขียนรายละเอียดเกี่ยวกับตัวคุณ...',
              hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.colorStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primaryBorder,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ค้นหา...',
                border: InputBorder.none,
              ),
            ),
          ),
          const Icon(Icons.search, color: Color(0xFFAAAAAA), size: 24),
        ],
      ),
    );
  }

  Widget _buildProvinceCheckboxList() {
    final provinceState = context.watch<ProvinceState>();
    final all = provinceState.provinces ?? [];

    List filtered = all
        .where(
          (p) => (p.nameTh ?? "").toLowerCase().contains(
            _searchText.toLowerCase(),
          ),
        )
        .toList();

    final checked =
        filtered.where((p) => _selectedProvinces[p.nameTh] == true).toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    final unchecked =
        filtered.where((p) => _selectedProvinces[p.nameTh] != true).toList()
          ..sort((a, b) => a.nameTh!.compareTo(b.nameTh!));

    List display = [...checked, ...unchecked];

    if (_searchText.isEmpty) {
      display = display.take(10).toList();
    }

    return Container(
      height: 350,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: display.length,
        itemBuilder: (context, i) {
          final p = display[i];
          final name = p.nameTh ?? "-";

          return CheckboxListTile(
            title: Text(name),
            value: _selectedProvinces[name] ?? false,
            onChanged: (v) {
              setState(() {
                _selectedProvinces[name] = v ?? false;
                _checkChanged();
              });
            },
            activeColor: const Color(0xFF3071C7),
            controlAffinity: ListTileControlAffinity.trailing,
          );
        },
      ),
    );
  }
}

//   List<Widget> _buildServiceCategories() {
//     return mockServiceCategories.asMap().entries.map((entry) {
//       int index = entry.key;
//       ServiceCategory category = entry.value;
//       BorderRadius radius = BorderRadius.zero;
//       if (index == 0) radius = const BorderRadius.vertical(top: Radius.circular(8));
//       if (index == mockServiceCategories.length - 1)
//         radius = const BorderRadius.vertical(bottom: Radius.circular(8));

//       return Container(
//         margin: const EdgeInsets.only(bottom: 0),
//         decoration: BoxDecoration(
//           color: const Color(0xFFE1EFFA),
//           borderRadius: radius,
//         ),
//         child: Theme(
//           data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
//           child: ExpansionTile(
//             title: Text(category.name,
//                 style:
//                 const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//             iconColor: AppColors.primaryHover,
//             collapsedIconColor: AppColors.primaryHover,
//             backgroundColor: Colors.transparent,
//             childrenPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
//             children: category.subServices.map(_buildSubServiceItem).toList(),
//           ),
//         ),
//       );
//     }).toList();
//   }

//   Widget _buildSubServiceItem(String subService) {
//     bool selected = _selectedServices[subService] ?? false;

//     return Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: selected ? AppColors.primaryBGHover : AppColors.primaryBG,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CheckboxListTile(
//             value: selected,
//             onChanged: (val) {
//               setState(() {
//                 _selectedServices[subService] = val ?? false;
//                 _checkChanged();
//               });
//             },
//             title: Text(subService,
//                 style:
//                 const TextStyle(fontSize: 14, color: AppColors.colorTertiaryText)),
//             controlAffinity: ListTileControlAffinity.trailing,
//             activeColor: const Color(0xFF3071C7),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 12),
//           ),
//           if (selected)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//               child: Row(
//                 children: [
//                   if (_priceType[subService] == "range") ...[
//                     Expanded(
//                       child: TextField(
//                         controller: _minPriceControllers[subService],
//                         decoration: _buildSmallPriceInputDecoration("Min Price"),
//                         keyboardType: TextInputType.number,
//                         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Icon(Icons.arrow_forward, color: AppColors.primaryBorderHover),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: TextField(
//                         controller: _maxPriceControllers[subService],
//                         decoration: _buildSmallPriceInputDecoration("Max Price"),
//                         keyboardType: TextInputType.number,
//                         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                       ),
//                     ),
//                   ],
//                   if (_priceType[subService] == "fix")
//                     Expanded(
//                       child: TextField(
//                         controller: _fixPriceControllers[subService],
//                         textAlign: TextAlign.right,
//                         decoration: _buildSmallPriceInputDecoration("Price"),
//                         keyboardType: TextInputType.number,
//                         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           if (selected)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//               child: Row(
//                 children: [
//                   const Spacer(),
//                   _buildPriceTypeChip(subService, "range", "Range price"),
//                   const SizedBox(width: 8),
//                   _buildPriceTypeChip(subService, "fix", "Fix price"),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   InputDecoration _buildSmallPriceInputDecoration(String hint) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: const TextStyle(color: AppColors.primaryBorder, fontSize: 14),
//       contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(6),
//         borderSide: const BorderSide(color: AppColors.primaryBorderHover),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(6),
//         borderSide: const BorderSide(color: AppColors.primaryBorderHover),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(6),
//         borderSide: const BorderSide(color: AppColors.primaryBorderHover, width: 2),
//       ),
//     );
//   }

//   Widget _buildPriceTypeChip(String subService, String type, String label) {
//     bool selected = _priceType[subService] == type;
//     return ChoiceChip(
//       label: Text(label,
//           style: TextStyle(
//               fontSize: 12,
//               color: selected
//                   ? AppColors.colorSecondaryText
//                   : AppColors.primaryBorderHover)),
//       selected: selected,
//       onSelected: (_) {
//         setState(() {
//           _priceType[subService] = type;
//           _checkChanged();
//         });
//       },
//       backgroundColor: AppColors.colorSecondaryText,
//       selectedColor: AppColors.primaryBorderHover,
//       shape: RoundedRectangleBorder(
//         side: BorderSide(color: AppColors.primarySecondaryBorder),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       showCheckmark: false,
//     );
//   }
// }
