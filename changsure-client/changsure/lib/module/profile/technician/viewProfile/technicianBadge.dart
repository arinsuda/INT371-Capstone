import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme.dart';
import '../../../../config/app_config.dart';
import '../../../../models/badges/badge.dart';

class TechnicianBadge extends StatelessWidget {
  final List<BadgeResponse> badges;

  const TechnicianBadge({super.key, required this.badges});

  static String _buildImageUrl(String iconUrl) {
    if (iconUrl.isEmpty) return '';

    if (iconUrl.startsWith('http://') || iconUrl.startsWith('https://')) {
      return iconUrl;
    }

    final path = iconUrl.startsWith('/') ? iconUrl.substring(1) : iconUrl;
    return '${AppConfig.minioBaseUrl}/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildHeader(), _buildBadgeList()],
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 0, left: 4, top: 24),
      child: Row(
        children: [
          Icon(Icons.emoji_events, size: 16, color: Colors.black),
          SizedBox(width: 6),
          Text(
            'ป้ายสัญลักษณ์ของช่าง',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeList() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: badges.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "ยังไม่มีป้ายสัญลักษณ์",
                style: TextStyle(fontSize: 13, color: Color(0xFF9B9B9B)),
              ),
            )
          : SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _BadgeItem(badge: badges[index]);
                },
              ),
            ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final BadgeResponse badge;

  const _BadgeItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    final imageUrl = TechnicianBadge._buildImageUrl(badge.iconUrl);

    debugPrint("🎯 Badge: ${badge.name}");
    debugPrint("📍 URL: $imageUrl");

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBadgeImage(imageUrl),
        const SizedBox(height: 8),
        _buildBadgeName(),
      ],
    );
  }

  Widget _buildBadgeImage(String url) {
    return SizedBox(
      width: 70,
      height: 70,
      child: url.isEmpty
          ? _buildPlaceholder()
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => _buildLoading(),
              errorWidget: (_, __, error) {
                debugPrint("❌ Badge Error: $error");
                return _buildError();
              },
              fadeInDuration: const Duration(milliseconds: 200),
              maxHeightDiskCache: 200,
              maxWidthDiskCache: 200,
            ),
    );
  }

  Widget _buildPlaceholder() {
    return Icon(Icons.badge_outlined, size: 35, color: Colors.grey.shade400);
  }

  Widget _buildLoading() {
    return Center(
      child: SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 30,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildBadgeName() {
    return SizedBox(
      width: 80,
      child: Text(
        badge.name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
          height: 1.2,
        ),
      ),
    );
  }
}
