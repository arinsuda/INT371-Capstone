import 'package:changsure/core/theme.dart';
import 'package:changsure/state/activity_editor_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityTextArea extends ConsumerWidget {
  final int activityId;

  const ActivityTextArea({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = activityEditorProvider(activityId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    final hasError = state.descriptionError != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError ? AppColors.colorError : AppColors.colorStroke,
                width: hasError ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: notifier.descriptionController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "กรอกคำอธิบายผลงาน...",
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                state.descriptionError!,
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
}
