import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../state/bottomBarState.dart';
import '../../../state/province_state.dart';
import '../../../state/profile_state.dart';
import 'package:flutter/services.dart';

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    if (text[0] != '0') {
      return oldValue;
    }

    String formatted = '';

    for (int i = 0; i < text.length && i < 10; i++) {
      if (i == 3 || i == 6) {
        formatted += '-';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  Map<String, bool> _selectedProvinces = {};
  String _searchText = '';

  bool hasChanged = false;
  bool _avatarChanged = false;

  String? _provinceError;

  void _checkChanged() {
    bool changed = false;
    bool hasSelectedProvince = false;

    changed |= nameController.text != '';
    changed |= lastNameController.text != '';
    changed |= emailController.text != '';
    changed |= phoneController.text != '';
    changed |= aboutController.text != '';

    hasSelectedProvince = _selectedProvinces.values.any((v) => v);
    changed |= hasSelectedProvince;
    changed |= _avatarChanged;

    bool validationPassed = _validateAll();

    bool shouldEnable =
        changed && hasSelectedProvince;

    if (shouldEnable != hasChanged) {
      setState(() {
        hasChanged = shouldEnable;
      });
    }
  }

  String formatPhoneNumber(String raw) {
    // ลบทุกตัวอักษรที่ไม่ใช่ตัวเลขก่อน
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';

    String formatted = '';
    for (int i = 0; i < digits.length && i < 10; i++) {
      if (i == 3 || i == 6) formatted += '-';
      formatted += digits[i];
    }
    return formatted;
  }


  bool _validateAll() {
    // Validate Province
    String? newProvinceError = _selectedProvinces.values.any((v) => v)
        ? null
        : "กรุณาเลือกข้อมูลให้ครบถ้วน";

    // Update state ถ้ามีการเปลี่ยนแปลง
    if (_provinceError != newProvinceError) {
      setState(() {
        _provinceError = newProvinceError;
      });
    } else {
      _provinceError = newProvinceError;
    }

    // Return true ถ้าไม่มี error
    return _provinceError == null;
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

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim();
      });
    });

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
        phoneController.text = formatPhoneNumber(tech.phone ?? '');
        aboutController.text = tech.bio;

        for (var p in provinces.provinces ?? []) {
          _selectedProvinces[p.nameTh ?? ""] = tech.provinces.any(
            (tp) => tp.id == p.id,
          );
        }
      }

      nameController.addListener(_checkChanged);
      lastNameController.addListener(_checkChanged);
      emailController.addListener(_checkChanged);
      phoneController.addListener(_checkChanged);
      aboutController.addListener(_checkChanged);

      setState(() {});
    });

    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim());
    });
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );

    if (file == null) return;

    await context.read<ProfileState>().changeAvatar(file.path);

    setState(() {
      _avatarChanged = true;
      _checkChanged(); // update button state
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
        child: Form(
          key: _formKey,
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

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child:
                      GestureDetector(
                        onTap: () => _pickAvatar(context),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0xFFE8E8E8),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildTextField(
                "ชื่อ",
                nameController,
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกชื่อ";
                  if (v.length < 2) return "ชื่อต้องมีอย่างน้อย 2 ตัวอักษร";
                  return null;
                },
              ),

              _buildTextField(
                "นามสกุล",
                lastNameController,
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกนามสกุล";
                  return null;
                },
              ),

              _buildTextField(
                "อีเมล",
                emailController,
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกอีเมล";
                  if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(v)) {
                    return "รูปแบบอีเมลไม่ถูกต้อง";
                  }
                  return null;
                },
              ),

              _buildTextField(
                "เบอร์โทร",
                phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                  _PhoneNumberFormatter(),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกเบอร์โทร";
                  if (!RegExp(r"^[0-9]{3}-[0-9]{3}-[0-9]{4}$").hasMatch(v)) {
                    return "เบอร์โทรต้องมี 10 หลัก";
                  }
                  return null;
                },
              ),

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

              if (_provinceError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    _provinceError!,
                    style: const TextStyle(
                      color: AppColors.colorError,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: PrimaryButton(
                  text: "บันทึกการแก้ไข",
                  onPressed: hasChanged
                      ? () async {
                          final profile = context.read<ProfileState>();
                          final provinceData = context.read<ProvinceState>();
                          String rawPhone = phoneController.text.replaceAll('-', '');

                          final selectedIds = _selectedProvinces.entries
                              .where((e) => e.value)
                              .map((e) {
                                final match = provinceData.provinces!
                                    .firstWhere((p) => p.nameTh == e.key);
                                return match.id;
                              })
                              .toList();

                          await profile.updateProfile(
                            firstname: nameController.text.trim(),
                            lastname: lastNameController.text.trim(),
                            email: emailController.text.trim(),
                            phone: rawPhone,
                            bio: aboutController.text.trim(),
                          );

                          print("ชื่อ"+ nameController.text.trim());
                          print("นามสกุล"+ lastNameController.text.trim(),);
                          print("อีเมล"+ emailController.text.trim());
                          print("โทร"+ phoneController.text.trim().replaceAll('-', ''));
                          print("เกี่ยวกับ"+ aboutController.text.trim());

                          await profile.updateTechnicianProvinces(selectedIds);

                          setState(() {
                            _avatarChanged = false;
                            _checkChanged();
                          });

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("บันทึกสำเร็จ")),
                            );
                            Provider.of<BottomBarState>(
                              context,
                              listen: false,
                            ).closeSubPage();
                          }
                        }
                      : null,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
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
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.colorStroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.colorStroke),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.colorError,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primaryBorder,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.colorError,
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(
                color: AppColors.colorError,
                fontSize: 12,
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

