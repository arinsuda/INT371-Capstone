import 'package:changsure/core/button/tertiary_button.dart';
import 'package:flutter/material.dart';
import '../../../../core/button/primary_button.dart';
import '../../../../core/theme.dart';

class FilterList extends StatefulWidget {
  final Map<String, dynamic> initialFilter;

  const FilterList({super.key, required this.initialFilter});

  @override
  State<FilterList> createState() => _FilterListState();
}

class _FilterListState extends State<FilterList> {
  /// เลือก Tag
  String selectedPrice = "";
  String selectedRating = "";
  String selectedDistance = "";

  /// Badge filter
  bool topService = false;
  bool recommended = false;
  bool highRating = false;
  bool fastResponse = false;

  @override
  void initState() {
    super.initState();

    selectedPrice = widget.initialFilter["price"] ?? "";
    selectedRating = widget.initialFilter["rating"] ?? "";
    selectedDistance = widget.initialFilter["distance"] ?? "";

    topService = widget.initialFilter["topService"] ?? false;
    recommended = widget.initialFilter["recommended"] ?? false;
    highRating = widget.initialFilter["highRating"] ?? false;
    fastResponse = widget.initialFilter["fastResponse"] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        right: 18,
        left: 18,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- HEADER ----------------
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.primaryText,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: AppColors.primaryText,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "ตัวกรอง",
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ---------------- FILTER: PRICE ----------------
          _section(
            title: "ราคา",
            child: Row(
              children: [
                _selectTag(
                  "ราคาสูง → ต่ำ",
                  selectedPrice,
                  (v) => setState(() => selectedPrice = v),
                ),
                const SizedBox(width: 10),
                _selectTag(
                  "ราคาต่ำ → สูง",
                  selectedPrice,
                  (v) => setState(() => selectedPrice = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---------------- FILTER: RATING ----------------
          _section(
            title: "เรทรีวิว",
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                _selectTagWithIcon(
                  "5",
                  selectedRating,
                  (v) => setState(() => selectedRating = v),
                ),
                _selectTagWithIcon(
                  "≥4",
                  selectedRating,
                  (v) => setState(() => selectedRating = v),
                ),
                _selectTagWithIcon(
                  "≥3",
                  selectedRating,
                  (v) => setState(() => selectedRating = v),
                ),
                _selectTagWithIcon(
                  "≥2",
                  selectedRating,
                  (v) => setState(() => selectedRating = v),
                ),
                _selectTagWithIcon(
                  "≥1",
                  selectedRating,
                  (v) => setState(() => selectedRating = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---------------- FILTER: DISTANCE ----------------
          _section(
            title: "ระยะทาง",
            child: Row(
              children: [
                _selectTag(
                  "ระยะทางใกล้ - ไกล",
                  selectedDistance,
                  (v) => setState(() => selectedDistance = v),
                ),
                const SizedBox(width: 10),
                _selectTag(
                  "ระยะทางไกล - ใกล้",
                  selectedDistance,
                  (v) => setState(() => selectedDistance = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---------------- FILTER: BADGES ----------------
          _section(
            title: "ตราสัญลักษณ์ช่าง",
            child: Padding(
              padding: const EdgeInsets.only(left: 0), // เริ่มตรงกับ Row ราคา
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.start,
                children: [
                  _badgeTag(
                    selected: topService,
                    text: "Top Service",
                    image: "assets/icons/top_service.png",
                    onTap: () => setState(() => topService = !topService),
                  ),
                  _badgeTag(
                    selected: recommended,
                    text: "ChangSure Recommend",
                    image: "assets/icons/changSure_rec.png",
                    onTap: () => setState(() => recommended = !recommended),
                  ),
                  _badgeTag(
                    selected: highRating,
                    text: "High Rating",
                    image: "assets/icons/high_rating.png",
                    onTap: () => setState(() => highRating = !highRating),
                  ),
                  _badgeTag(
                    selected: fastResponse,
                    text: "Fast Response",
                    image: "assets/icons/fast_response.png",
                    onTap: () => setState(() => fastResponse = !fastResponse),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ---------------- BUTTONS ----------------
          Row(
            children: [
              Expanded(
                child: TertiaryButton(
                  text: "รีเซ็ต",
                  onPressed: () {
                    setState(() {
                      selectedPrice = "";
                      selectedRating = "";
                      selectedDistance = "";
                      topService = false;
                      recommended = false;
                      highRating = false;
                      fastResponse = false;
                    });
                  },
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: "ยืนยัน",
                  onPressed: () {
                    Navigator.pop(context, {
                      "price": selectedPrice,
                      "rating": selectedRating,
                      "distance": selectedDistance,
                      "topService": topService,
                      "recommended": recommended,
                      "highRating": highRating,
                      "fastResponse": fastResponse,
                    });
                  },
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- COMPONENT: TITLE + CONTENT ----------------
  Widget _section({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  // ---------------- SELECT TAG ----------------
  Widget _selectTag(String label, String current, Function(String) onTap) {
    final bool isSelected = label == current;

    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? AppColors.primaryBGHover
              : const Color(0xFFF2F2F2),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _selectTagWithIcon(
    String label,
    String current,
    Function(String) onTap,
  ) {
    final bool isSelected = label == current;

    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? AppColors.primaryBGHover
              : const Color(0xFFF2F2F2),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.star_rate_rounded, size: 16, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  // ---------------- BADGE TAG ----------------
  Widget _badgeTag({
    required bool selected,
    required String text,
    required String image,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBGHover : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Color(0xFFF2F2F2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(image, width: 16, height: 16),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
