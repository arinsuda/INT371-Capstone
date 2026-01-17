import 'package:changsure/data/services/public_technician_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:changsure/data/models/technician/public_post_model.dart';
import 'package:changsure/data/models/technician/public_technician_model.dart';

class PublicPostsParams {
  final int technicianId;
  final int? categoryId;
  final int? serviceId;
  final String? search;

  const PublicPostsParams({
    required this.technicianId,
    this.categoryId,
    this.serviceId,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicPostsParams &&
          technicianId == other.technicianId &&
          categoryId == other.categoryId &&
          serviceId == other.serviceId &&
          search == other.search;

  @override
  int get hashCode => Object.hash(technicianId, categoryId, serviceId, search);
}

final publicTechnicianProvider =
    StateNotifierProvider.family<
      PublicTechnicianNotifier,
      AsyncValue<PublicTechnicianProfile?>,
      int
    >((ref, technicianId) {
      return PublicTechnicianNotifier(ref, technicianId);
    });

class PublicTechnicianNotifier
    extends StateNotifier<AsyncValue<PublicTechnicianProfile?>> {
  final Ref ref;
  final int technicianId;
  final PublicTechnicianService _service = PublicTechnicianService();

  PublicTechnicianNotifier(this.ref, this.technicianId)
    : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();

    try {
      final token = ref.read(userProvider)?.token;
      if (token == null || token.isEmpty) {
        throw Exception('Missing token');
      }

      final profile = await _service.getPublicProfile(
        technicianId,
        token: token,
      );

      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final publicPostsProvider =
    StateNotifierProvider.family<
      PublicPostsNotifier,
      AsyncValue<List<PublicPost>>,
      PublicPostsParams
    >((ref, params) {
      return PublicPostsNotifier(ref, params);
    });

class PublicPostsNotifier extends StateNotifier<AsyncValue<List<PublicPost>>> {
  final Ref ref;
  final PublicPostsParams params;
  final PublicTechnicianService _service = PublicTechnicianService();

  int _currentPage = 1;
  bool _hasMore = true;
  int _total = 0;

  PublicPostsNotifier(this.ref, this.params)
    : super(const AsyncValue.loading()) {
    loadPosts(reset: true);
  }

  Future<void> loadPosts({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _total = 0;
      state = const AsyncValue.loading();
    }

    if (!_hasMore) return;

    try {
      final token = ref.read(userProvider)?.token;
      if (token == null || token.isEmpty) throw Exception('Missing token');

      final result = await _service.getPublicPosts(
        params.technicianId,
        token: token,
        page: _currentPage,
        categoryId: params.categoryId,
        serviceId: params.serviceId,
        search: params.search,
      );

      if (result == null) {
        _hasMore = false;
        state = AsyncValue.data(state.value ?? []);
        return;
      }

      final posts = result['posts'] as List<PublicPost>;
      _total = result['total'] as int;

      final current = reset ? <PublicPost>[] : (state.value ?? []);
      final merged = [...current, ...posts];

      state = AsyncValue.data(merged);

      _hasMore = merged.length < _total;
      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void refresh() => loadPosts(reset: true);
}
