import 'package:flutter/material.dart';
import '../../../../models/technicians/tech_service.dart';
import '../../../../core/theme.dart';

class ServiceTag extends StatelessWidget {
  final List<TechServiceResponse> services; // ✅ รับจาก API

  const ServiceTag({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const Text(
        "ยังไม่มีบริการที่เปิดรับ",
        style: TextStyle(fontSize: 13, color: Color(0xFF9B9B9B)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: services.map((s) {
        final priceLabel = s.pricingType == 'FIXED'
            ? "${s.priceFixed} บาท"
            : "${s.priceMin}-${s.priceMax} บาท";

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.serviceName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                priceLabel,
                style: const TextStyle(fontSize: 11, color: Color(0xFF545454)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
