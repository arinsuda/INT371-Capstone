import 'package:changsure/module/profile/technician/activities/pages/activity_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/bottom_nav_provider.dart';
import '../theme.dart';

class TechnicianCard extends ConsumerWidget {
  final int id;
  final String serviceCategoryName;
  final String description;
  final List<String> images;
  final int? technicianId;
  final bool isPublicView;

  const TechnicianCard({
    super.key,
    required this.id,
    required this.serviceCategoryName,
    required this.description,
    required this.images,
    this.technicianId,
    this.isPublicView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, Map<String, Color>> colorMap = {
      "งานทาสี": {
        "text": const Color(0xFFEB2F96),
        "background": const Color(0xFFFFF0F6),
        "border": const Color(0xFFFFADD2),
      },
      "งานประปา": {
        "text": const Color(0xFF36CFC9),
        "background": const Color(0xFFE6FFFB),
        "border": const Color(0xFF87E8DE),
      },
      "งานไฟฟ้า": {
        "text": const Color(0xFFFAAD14),
        "background": const Color(0xFFFFFBE6),
        "border": const Color(0xFFFFE58F),
      },
      "งานซ่อมเครื่องใช้ไฟฟ้า": {
        "text": const Color(0xFF722ED1),
        "background": const Color(0xFFF9F0FF),
        "border": const Color(0xFFD3ADF7),
      },
    };

    final categoryColors =
        colorMap[serviceCategoryName] ??
        {
          "text": Colors.purple,
          "background": Colors.purple.shade100,
          "border": Colors.purple.shade300,
        };

    Widget buildImages() {
      double imageHeight = MediaQuery.of(context).size.height * 0.1;
      if (images.isEmpty) {
        return Container(
          height: imageHeight * 1.2,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.image_not_supported, color: Colors.grey),
          ),
        );
      }

      if (images.length == 1) {
        return Image.network(
          images[0],
          height: imageHeight * 1.2,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 120,
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.broken_image)),
          ),
        );
      }

      if (images.length == 2) {
        return Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                ),
                child: Image.network(
                  images[0],
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  images[1],
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(color: Colors.grey.shade200),
                ),
              ),
            ),
          ],
        );
      }
      int displayCount = images.length > 3 ? 3 : images.length;
      int extraCount = images.length - 3;

      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
              ),
              child: Image.network(
                images[0],
                height: imageHeight * 1.2,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: imageHeight* 1.2,
              child: Column(
                children: List.generate(
                  displayCount - 1,
                  (index) {
                    bool isLastWithExtra = index == 1 && extraCount > 0;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: index == 0 ? 4.0 : 0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                images[index + 1],
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    Container(color: Colors.grey.shade200),
                              ),
                            ),
                            if (isLastWithExtra)
                              Container(
                                color: Colors.black.withOpacity(0.5),
                                child: Center(
                                  child: Text(
                                    '+$extraCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        if (isPublicView && technicianId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ActivityDetailPage(postId: id, technicianId: technicianId!),
            ),
          );
        } else {
          ref.read(bottomSubPageProvider.notifier).state = SubPageConfig(
            page: BottomSubPage.technicianViewActivityById,
            activityId: id,
          );
        }
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // ✅ ลบ ClipRRect ที่ครอบ buildImages() ออก
                // เพราะมันไป clip overlay +N ทิ้ง
                // แต่ละ case ใน buildImages() มี ClipRRect ของตัวเองแล้ว
                buildImages(),
                Positioned(
                  top: 0,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColors["background"],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      serviceCategoryName,
                      style: TextStyle(
                        color: categoryColors["text"],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: SizedBox(
                height: 40,
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.colorTertiaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "ดูรายละเอียดเพิ่มเติม",
                style: TextStyle(
                  color: AppColors.primaryBorderHover,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
