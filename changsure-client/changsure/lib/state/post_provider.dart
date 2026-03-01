import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/data/models/technician/post_model.dart';
import '../data/services/technician_service.dart';
import 'user_provider.dart';

final selectedCategoryFilterProvider = StateProvider<int?>((ref) => null);

final technicianPostsProvider = FutureProvider.autoDispose<List<PostModel>>((
  ref,
) async {
  final userState = ref.watch(userProvider);
  final categoryId = ref.watch(selectedCategoryFilterProvider);

  if (userState == null || userState.token == null) {
    return [];
  }

  final service = TechnicianService();
  return await service.getMyPosts(
    token: userState.token!,
    technicianId: userState.id,
    categoryId: categoryId,
  );
});
