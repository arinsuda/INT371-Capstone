import 'package:changsure/core/header.dart';
import 'package:changsure/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/button/tertiary_button.dart';
import '../../../../state/bottom_bar_state.dart';
import '../../../../state/ativity_state.dart';
import '../view_activities.dart';
import 'edit_activity_by_id.dart';

class ViewActivityById extends StatefulWidget {
  final int id;

  const ViewActivityById({super.key, required this.id});

  @override
  State<ViewActivityById> createState() => _ViewActivityByIdState();
}

class _ViewActivityByIdState extends State<ViewActivityById> {
  final Map<String, Map<String, Color>> colorMap = {
    "ช่างทาสี": {
      "text": Color(0xFFEB2F96),
      "background": Color(0xFFFFF0F6),
      "border": Color(0xFFFFADD2),
    },
    "ช่างประปา": {
      "text": Color(0xFF36CFC9),
      "background": Color(0xFFE6FFFB),
      "border": Color(0xFF87E8DE),
    },
    "ช่างไฟฟ้า": {
      "text": Color(0xFFFAAD14),
      "background": Color(0xFFFFFBE6),
      "border": Color(0xFFFFE58F),
    },
    "ช่างซ่อมเครื่องใช้ไฟฟ้า": {
      "text": Color(0xFF722ED1),
      "background": Color(0xFFF9F0FF),
      "border": Color(0xFFD3ADF7),
    },
  };

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<TechnicianWorkState>().loadWorkById(widget.id);
    });
  }

  void _showDeleteModal(BuildContext context, int id) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "ลบผลงาน",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "คุณแน่ใจหรือไม่ว่าต้องการลบผลงานนี้? การลบเป็นแบบถาวรและไม่สามารถกู้คืนได้",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TertiaryButton(
                        text: "ยกเลิก",
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF5222D)),
                          foregroundColor: Color(0xFFF5222D),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);

                          final ok = await context
                              .read<TechnicianWorkState>()
                              .deleteWork(id);

                          if (ok && mounted) {
                            context.read<BottomBarState>().setSubPage(
                              const ViewActivities(),
                            );
                          }
                        },
                        child: const Text(
                          "ลบ",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workState = context.watch<TechnicianWorkState>();
    final work = workState.currentWork;

    if (workState.isLoading || work == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final categoryColor = colorMap[work.serviceName ?? ""];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Header(
                header: "ดูผลงาน",
                onPressed: () {
                  context.read<BottomBarState>().setSubPage(
                    const ViewActivities(),
                  );
                },
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(
                        "assets/image/Technician.png",
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "คุณ สมชาย รักชาติ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  categoryColor?["background"] ??
                                  Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: categoryColor?["border"] ?? Colors.grey,
                              ),
                            ),
                            child: Text(
                              work.serviceName ?? "ไม่ระบุหมวด",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: categoryColor?["text"] ?? Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    PopupMenuButton<String>(
                      elevation: 4,
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.read<BottomBarState>().setSubPage(
                            EditActivityById(id: work.id),
                          );
                        } else if (value == 'delete') {
                          _showDeleteModal(context, work.id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.create_rounded,
                                size: 20,
                                color: AppColors.colorTertiaryText,
                              ),
                              const SizedBox(width: 12),
                              const Text("แก้ไขโพสต์"),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete,
                                size: 20,
                                color: AppColors.colorTertiaryText,
                              ),
                              const SizedBox(width: 12),
                              const Text("ลบโพสต์"),
                            ],
                          ),
                        ),
                      ],
                      child: SvgPicture.asset(
                        'assets/icons/optionIcon.svg',
                        height: 20,
                        width: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  work.description ?? "",
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: work.images.map((img) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(img.imageUrl, fit: BoxFit.cover),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
