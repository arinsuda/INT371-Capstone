import 'package:changsure/core/theme.dart'; // import AppColors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/state/activity_editor_state.dart';

class ActivityImageUploader extends ConsumerWidget {
  final int activityId;

  const ActivityImageUploader({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityEditorProvider(activityId));
    final notifier = ref.read(activityEditorProvider(activityId).notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Asset Images
              ...state.assetImages.asMap().entries.map((entry) {
                return _buildImageItem(
                  Image.asset(
                    entry.value,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                  () => notifier.removeAssetImage(entry.key),
                );
              }),
              // Picked Images
              ...state.pickedImages.asMap().entries.map((entry) {
                return _buildImageItem(
                  Image.file(
                    entry.value,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                  () => notifier.removePickedImage(entry.key),
                );
              }),
              // Add Button
              GestureDetector(
                onTap: notifier.pickImage,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.imageError != null
                          ? AppColors.colorError
                          : AppColors.colorStroke,
                      width: state.imageError != null ? 1.5 : 1,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: state.imageError != null
                        ? AppColors.colorError
                        : AppColors.primaryBorder,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          if (state.imageError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                state.imageError!,
                style: const TextStyle(
                  color: AppColors.colorError,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageItem(Widget image, VoidCallback onDelete) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
