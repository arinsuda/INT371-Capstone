import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';
import 'package:provider/provider.dart';
import '../../../mockDB/province.dart';
import '../../../mockDB/servicesCategories.dart';
import '../../../state/bottomBarState.dart';
import 'package:flutter/services.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController nameController =
  TextEditingController(text: 'สมชาย');
  final TextEditingController lastNameController =
  TextEditingController(text: 'ใจดี');
  final TextEditingController emailController =
  TextEditingController(text: 'somchai@gmail.com');
  final TextEditingController phoneController =
  TextEditingController(text: '088-888-8888');
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController aboutController = TextEditingController(
      text:
      'ช่างไฟฟ้ามากประสบการณ์กว่า 10 ปี เชี่ยวชาญงานซ่อมไฟฟ้าและติดตั้งอุปกรณ์ภายในบ้าน');

  Map<String, bool> _selectedProvinces = {};
  String _searchText = '';

  Map<String, bool> _selectedServices = {};
  Map<String, String> _priceType = {}; // "fix" หรือ "range"
  Map<String, TextEditingController> _minPriceControllers = {};
  Map<String, TextEditingController> _maxPriceControllers = {};
  Map<String, TextEditingController> _fixPriceControllers = {};
  bool hasChanged = false;

  // ---------- ฟังก์ชันเช็คการแก้ไข ----------
  void _checkChanged() {
    bool changed = false;

    // 1. TextFields
    changed |= nameController.text != 'สมชาย';
    changed |= lastNameController.text != 'ใจดี';
    changed |= emailController.text != 'somchai@gmail.com';
    changed |= phoneController.text != '088-888-8888';
    changed |=
        aboutController.text !=
            'ช่างไฟฟ้ามากประสบการณ์กว่า 10 ปี เชี่ยวชาญงานซ่อมไฟฟ้าและติดตั้งอุปกรณ์ภายในบ้าน';

    // 2. จังหวัด
    changed |= _selectedProvinces.values.any((v) => v);

    // 3. Services + ราคาของ subService
    for (var sub in _selectedServices.keys) {
      changed |= _selectedServices[sub] == true; // ถ้าเลือก service
      if (_selectedServices[sub] == true) {
        if (_priceType[sub] == "range") {
          changed |= (_minPriceControllers[sub]?.text.isNotEmpty ?? false);
          changed |= (_maxPriceControllers[sub]?.text.isNotEmpty ?? false);
        } else if (_priceType[sub] == "fix") {
          changed |= (_fixPriceControllers[sub]?.text.isNotEmpty ?? false);
        }
      }
    }

    if (changed != hasChanged) {
      setState(() {
        hasChanged = changed;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _selectedProvinces = {for (var p in mockProvinces) p: false};

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim();
      });
    });

    for (var category in mockServiceCategories) {
      for (var sub in category.subServices) {
        _selectedServices[sub] = false;
        _priceType[sub] = "range";
        _minPriceControllers[sub] = TextEditingController();
        _maxPriceControllers[sub] = TextEditingController();
        _fixPriceControllers[sub] = TextEditingController();

        _minPriceControllers[sub]?.addListener(_checkChanged);
        _maxPriceControllers[sub]?.addListener(_checkChanged);
        _fixPriceControllers[sub]?.addListener(_checkChanged);
      }
    }

    // Listener ฟิลด์หลัก
    nameController.addListener(_checkChanged);
    lastNameController.addListener(_checkChanged);
    emailController.addListener(_checkChanged);
    phoneController.addListener(_checkChanged);
    aboutController.addListener(_checkChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            // ---------- Header ----------
            Header(header: "แก้ไขโปรไฟล์"),
            const SizedBox(height: 16),
            // ---------- Avatar ----------
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage:
                    AssetImage('assets/image/Technician.png'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ---------- Form Fields ----------
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

            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "ประเภทงานที่รับบริการ",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.colorTertiaryText,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(children: _buildServiceCategories()),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: PrimaryButton(
                text: "บันทึกการแก้ไข",
                onPressed: hasChanged
                    ? () {
                  // ทำงานตอนกดบันทึก
                }
                    : null, // disabled ถ้าไม่มีการแก้ไข
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------- Widgets ----------
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.colorTertiaryText,
                  fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.colorTertiaryText,
                  fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: 5,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'เขียนรายละเอียดเกี่ยวกับตัวคุณ...',
              hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.colorStroke)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.colorStroke)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColors.primaryBorder, width: 2)),
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
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ค้นหา...',
                hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
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
    List<String> filtered = mockProvinces
        .where((p) => p.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();
    List<String> checked =
    filtered.where((p) => _selectedProvinces[p] == true).toList()..sort();
    List<String> unchecked =
    filtered.where((p) => _selectedProvinces[p] != true).toList()..sort();
    List<String> displayList = [...checked, ...unchecked];
    if (_searchText.isEmpty) displayList = displayList.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: displayList.map((province) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Theme(
              data: Theme.of(context)
                  .copyWith(unselectedWidgetColor: AppColors.primaryBorder),
              child: CheckboxListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(
                        color: AppColors.primaryBorder, width: 1)),
                title: Text(province,
                    style: const TextStyle(
                        color: AppColors.colorTertiaryText, fontSize: 14)),
                value: _selectedProvinces[province] ?? false,
                onChanged: (val) {
                  setState(() {
                    _selectedProvinces[province] = val ?? false;
                    _checkChanged();
                  });
                },
                activeColor: const Color(0xFF3071C7),
                controlAffinity: ListTileControlAffinity.trailing,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- ส่วน Service ----------
  List<Widget> _buildServiceCategories() {
    return mockServiceCategories.asMap().entries.map((entry) {
      int index = entry.key;
      ServiceCategory category = entry.value;
      BorderRadius radius = BorderRadius.zero;
      if (index == 0) radius = const BorderRadius.vertical(top: Radius.circular(8));
      if (index == mockServiceCategories.length - 1)
        radius = const BorderRadius.vertical(bottom: Radius.circular(8));

      return Container(
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: const Color(0xFFE1EFFA),
          borderRadius: radius,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(category.name,
                style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            iconColor: AppColors.primaryHover,
            collapsedIconColor: AppColors.primaryHover,
            backgroundColor: Colors.transparent,
            childrenPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            children: category.subServices.map(_buildSubServiceItem).toList(),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSubServiceItem(String subService) {
    bool selected = _selectedServices[subService] ?? false;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryBGHover : AppColors.primaryBG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: selected,
            onChanged: (val) {
              setState(() {
                _selectedServices[subService] = val ?? false;
                _checkChanged();
              });
            },
            title: Text(subService,
                style:
                const TextStyle(fontSize: 14, color: AppColors.colorTertiaryText)),
            controlAffinity: ListTileControlAffinity.trailing,
            activeColor: const Color(0xFF3071C7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (_priceType[subService] == "range") ...[
                    Expanded(
                      child: TextField(
                        controller: _minPriceControllers[subService],
                        decoration: _buildSmallPriceInputDecoration("Min Price"),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: AppColors.primaryBorderHover),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _maxPriceControllers[subService],
                        decoration: _buildSmallPriceInputDecoration("Max Price"),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                  if (_priceType[subService] == "fix")
                    Expanded(
                      child: TextField(
                        controller: _fixPriceControllers[subService],
                        textAlign: TextAlign.right,
                        decoration: _buildSmallPriceInputDecoration("Price"),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                ],
              ),
            ),
          if (selected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Spacer(),
                  _buildPriceTypeChip(subService, "range", "Range price"),
                  const SizedBox(width: 8),
                  _buildPriceTypeChip(subService, "fix", "Fix price"),
                ],
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildSmallPriceInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.primaryBorder, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.primaryBorderHover),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.primaryBorderHover),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.primaryBorderHover, width: 2),
      ),
    );
  }

  Widget _buildPriceTypeChip(String subService, String type, String label) {
    bool selected = _priceType[subService] == type;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: selected
                  ? AppColors.colorSecondaryText
                  : AppColors.primaryBorderHover)),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _priceType[subService] = type;
          _checkChanged();
        });
      },
      backgroundColor: AppColors.colorSecondaryText,
      selectedColor: AppColors.primaryBorderHover,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primarySecondaryBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      showCheckmark: false,
    );
  }
}
