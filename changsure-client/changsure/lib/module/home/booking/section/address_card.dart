import 'package:flutter/material.dart';

import '../../../../core/theme.dart';

class AddressCard extends StatelessWidget {
  final VoidCallback? onTap;

  const AddressCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "ธนชนก บรรจงจินดา",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "0982887376",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.colorTertiaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "126 บ้านธรรมรักษา ถนนประชาอุทิศ บางมด ทุ่งครุ กรุงเทพมหานคร 10140",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.colorTertiaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: AppColors.colorTertiaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


