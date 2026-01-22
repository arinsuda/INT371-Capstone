import 'package:changsure/module/home/service/serviceDetails/technician_select_card.dart';
import 'package:changsure/module/home/service/serviceDetails/filter_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/header.dart';
import '../../../core/theme.dart';
import '../../../data/models/master_data_models.dart';
import '../../../state/master_data_provider.dart';
import '../../../state/user_provider.dart';

class CustomerChoose extends ConsumerStatefulWidget {
  final String serviceName;
  final int category;
  final int serviceId;
  final int? provinceId;
  final ServiceModel data;


  const CustomerChoose({
    super.key,
    required this.serviceName,
    required this.category,
    required this.serviceId,
    required this.provinceId,
    required this.data
  });

  @override
  ConsumerState<CustomerChoose> createState() => _CustomerChooseState();
}

class _CustomerChooseState extends ConsumerState<CustomerChoose> {
  List<Technician> _allTechnicians = [];
  List<Technician> _filteredTechnicians = [];
  bool _isLoading = true;

  bool _hasActiveBadge(Technician t, String badgeName) {
    return t.badges.any((b) => b.isActive && b.name == badgeName);
  }

  Map<String, dynamic> _currentFilter = {
    "price": "",
    "rating": "",
    "distance": "",
    "topService": false,
    "recommended": false,
    "highRating": false,
    "fastResponse": false,
  };

  void _applyFilter(Map<String, dynamic> filter) {
    List<Technician> list = [..._allTechnicians];

    /// -------- PRICE --------
    if (filter['price'] == "ราคาสูง → ต่ำ") {
      list.sort((a, b) => b.priceMin.compareTo(a.priceMin));
    } else if (filter['price'] == "ราคาต่ำ → สูง") {
      list.sort((a, b) => a.priceMin.compareTo(b.priceMin));
    }

    /// -------- RATING --------
    if (filter['rating'] != "") {
      final ratingStr = filter['rating'];
      final minRating = ratingStr.startsWith("≥")
          ? int.parse(ratingStr.replaceAll("≥", ""))
          : int.parse(ratingStr); // กรณี "5"

      list = list.where((t) => t.ratingAvg! >= minRating).toList();
    }

    /// -------- DISTANCE --------
    if (filter['distance'] == "ระยะทางใกล้ - ไกล") {
      list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else if (filter['distance'] == "ระยะทางไกล - ใกล้") {
      list.sort((a, b) => b.distanceKm.compareTo(a.distanceKm));
    }

    /// -------- BADGES --------
    if (filter['recommended'] == true) {
      list = list
          .where((t) => _hasActiveBadge(t, "ChangSure Recommend"))
          .toList();
    }

    if (filter['highRating'] == true) {
      list = list
          .where((t) => _hasActiveBadge(t, "High Rating"))
          .toList();
    }

    if (filter['topService'] == true) {
      list = list
          .where((t) => _hasActiveBadge(t, "Top Service"))
          .toList();
    }

    if (filter['fastResponse'] == true) {
      list = list
          .where((t) => _hasActiveBadge(t, "Fast Response"))
          .toList();
    }


    setState(() {
      _filteredTechnicians = list;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    final user = ref.read(userProvider);

    final result = await ref
        .read(masterDataServiceProvider)
        .getAllTechnician(
          user?.token,
          widget.serviceId,
          widget.provinceId ?? 0,
        );

    setState(() {
      _allTechnicians = result;
      _filteredTechnicians = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(widget.serviceId);
    print(widget.provinceId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Header(
              header: "เลือกช่างด้วยตนเอง",
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),

            //Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.serviceName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),
                  const Text(
                    "คุณต้องการเลือกช่างคนไหน",
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
              padding: EdgeInsets.only(right: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result =
                          await showModalBottomSheet<Map<String, dynamic>>(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (_) => FilterList(
                              initialFilter: Map<String, dynamic>.from(
                                _currentFilter,
                              ),
                            ),
                          );

                      if (result != null) {
                        setState(() {
                          _currentFilter = result;
                        });
                        _applyFilter(result);
                      }
                    },

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBGHover,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "ตัวกรอง",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.filter_list_rounded,
                            color: AppColors.primary,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (_) {
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_allTechnicians.isEmpty) {
                    return const Center(
                      child: Text(
                        'ไม่พบช่างในพื้นที่นี้',
                        style: TextStyle(color: AppColors.colorError),
                      ),
                    );
                  }

                  if (_filteredTechnicians.isEmpty) {
                    return const Center(
                      child: Text(
                        'ไม่พบช่างตามเงื่อนไข',
                        style: TextStyle(color: AppColors.colorError),
                      ),
                    );
                  }

                  return Column(
                    children: _filteredTechnicians
                        .map(
                          (tech) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TechnicianCardCTM(technician: tech, data:widget.data, provinceId: widget.provinceId),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
