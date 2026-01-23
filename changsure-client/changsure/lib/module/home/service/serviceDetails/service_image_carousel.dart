import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class ServiceImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const ServiceImageCarousel({
    super.key,
    required this.imageUrls,
  });

  @override
  State<ServiceImageCarousel> createState() => _ServiceImageCarouselState();
}

class _ServiceImageCarouselState extends State<ServiceImageCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;

    return SizedBox(
      height: 370,
      child: Stack(
        children: [
          // ===== PAGE VIEW =====
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final url = images[index];

              return Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, __, ___) {
                  return Image.asset(
                    'assets/images/clean1.png',
                    fit: BoxFit.cover,
                  );
                },
              );
            },
          ),

          // ===== COUNT (1/4) =====
          Positioned(
            right: 12,
            bottom: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // ===== DOT INDICATOR =====
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                final isActive = index == _currentIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                    isActive
                        ? AppColors.primary
                        : Colors.black.withOpacity(0.25),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
