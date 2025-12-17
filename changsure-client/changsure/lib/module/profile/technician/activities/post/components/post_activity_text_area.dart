import 'package:changsure/core/theme.dart';
import 'package:changsure/state/activity_editor_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/state/post_activity_state.dart';

class PostActivityTextArea extends ConsumerWidget {
  const PostActivityTextArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = activityEditorProvider(0);
    final notifier = ref.read(provider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.colorStroke),
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
    );
  }
}
