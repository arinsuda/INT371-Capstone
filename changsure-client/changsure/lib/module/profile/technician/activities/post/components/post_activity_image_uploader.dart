import 'package:changsure/core/theme.dart';
import 'package:changsure/state/activity_editor_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PostActivityImageUploader extends ConsumerWidget {
  const PostActivityImageUploader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = activityEditorProvider(0);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    final selectedImages = state.pickedImages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...selectedImages.asMap().entries.map((entry) {
            final index = entry.key;
            final img = entry.value;
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    img,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => notifier.removePickedImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
          GestureDetector(
            onTap: notifier.pickImage,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.colorStroke),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primaryBorder,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
