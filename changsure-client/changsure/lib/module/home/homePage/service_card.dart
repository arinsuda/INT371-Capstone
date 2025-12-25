import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/master_data_models.dart';
import '../../../mockDB/service_categories.dart';
import '../service/service_detail.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel data;
  final int? provinceId;

  const ServiceCard({super.key, required this.data, required this.provinceId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetail(id: data.id, data: data,
              provinceId: provinceId,),
          ),
        );
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: SizedBox(
          height: 210,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  data.imageUrls.first,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      'assets/image/no_image.png',
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.serName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),

                      // ราคา
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(
                            context,
                          ).style.copyWith(fontSize: 12),
                          children: [
                            const TextSpan(
                              text: "เริ่มต้น ",
                              style: TextStyle(
                                color: AppColors.colorTertiaryText,
                              ),
                            ),
                            TextSpan(
                              text: "฿${data.defaultPrice.min}",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
