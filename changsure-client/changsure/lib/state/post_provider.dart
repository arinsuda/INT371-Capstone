import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/data/models/technician/post_model.dart';
import 'package:changsure/data/models/technician/technician_model.dart'
    hide TechnicianService;
import 'package:changsure/data/services/technician_service.dart';
import 'user_provider.dart';

final selectedCategoryFilterProvider = StateProvider<int?>((ref) => null);

final technicianProfileProvider =
    StateNotifierProvider.family<
      TechnicianProfileNotifier,
      AsyncValue<TechnicianModel?>,
      int
    >((ref, technicianId) {
      return TechnicianProfileNotifier(ref, technicianId);
    });

class TechnicianProfileNotifier
    extends StateNotifier<AsyncValue<TechnicianModel?>> {
  final Ref ref;
  final int technicianId;

  TechnicianProfileNotifier(this.ref, this.technicianId)
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final token = ref.read(userProvider)?.token;
      if (token == null) throw Exception('No token');

      final service = TechnicianService();
      final profile = await service.getProfile(
        token: token,
        technicianId: technicianId,
      );
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void refresh() => load();
}

class PostsParams {
  final int technicianId;
  final int? categoryId;
  final int? serviceId;
  final String? search;
  final bool? isPublished;

  const PostsParams({
    required this.technicianId,
    this.categoryId,
    this.serviceId,
    this.search,
    this.isPublished,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostsParams &&
          technicianId == other.technicianId &&
          categoryId == other.categoryId &&
          serviceId == other.serviceId &&
          search == other.search &&
          isPublished == other.isPublished;

  @override
  int get hashCode =>
      Object.hash(technicianId, categoryId, serviceId, search, isPublished);
}

class PostsState {
  final List<PostModel> posts;
  final bool isLoading;
  final bool hasMore;
  final int total;

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.total = 0,
  });

  PostsState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? hasMore,
    int? total,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
    );
  }
}

final technicianPostsProvider =
    StateNotifierProvider.family<
      TechnicianPostsNotifier,
      PostsState,
      PostsParams
    >((ref, params) {
      return TechnicianPostsNotifier(ref, params);
    });

class TechnicianPostsNotifier extends StateNotifier<PostsState> {
  final Ref ref;
  final PostsParams params;
  int _currentPage = 1;

  TechnicianPostsNotifier(this.ref, this.params) : super(const PostsState()) {
    load(reset: true);
  }

  Future<void> load({bool reset = false}) async {
    if (state.isLoading) return;
    if (!reset && !state.hasMore) return;

    if (reset) {
      _currentPage = 1;
      state = const PostsState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final token = ref.read(userProvider)?.token;
      if (token == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final service = TechnicianService();
      final result = await service.getPosts(
        token: token,
        technicianId: params.technicianId,
        categoryId: params.categoryId,
        serviceId: params.serviceId,
        search: params.search,
        isPublished: params.isPublished,
        page: _currentPage,
      );

      if (result == null) {
        state = state.copyWith(isLoading: false, hasMore: false);
        return;
      }

      final newPosts = result['posts'] as List<PostModel>;
      final total = result['total'] as int;
      final allPosts = reset ? newPosts : [...state.posts, ...newPosts];

      state = PostsState(
        posts: allPosts,
        isLoading: false,
        hasMore: allPosts.length < total,
        total: total,
      );
      _currentPage++;
    } catch (e) {
      print('❌ Load Posts Error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void loadMore() => load();
  void refresh() => load(reset: true);
}

final myPostsProvider = FutureProvider.autoDispose<List<PostModel>>((
  ref,
) async {
  final user = ref.watch(userProvider);
  final categoryId = ref.watch(selectedCategoryFilterProvider);

  if (user?.token == null) return [];

  final service = TechnicianService();
  final result = await service.getPosts(
    token: user!.token!,
    technicianId: user.id,
    categoryId: categoryId,
  );
  return (result?['posts'] as List<PostModel>?) ?? [];
});
