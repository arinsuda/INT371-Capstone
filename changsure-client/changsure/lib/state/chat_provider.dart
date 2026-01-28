import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat/chat_model.dart';
import '../data/services/chat_service.dart';
import 'user_provider.dart';

final chatServiceProvider = Provider((ref) => ChatService());

final chatRoomsProvider = FutureProvider.autoDispose<List<ChatRoom>>((
  ref,
) async {
  final service = ref.watch(chatServiceProvider);
  final user = ref.watch(userProvider);
  if (user?.token == null) throw Exception("Unauthorized");

  return service.getChatRooms(user!.token!);
});

final chatHistoryProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, int>((ref, bookingId) async {
      final service = ref.watch(chatServiceProvider);
      final user = ref.watch(userProvider);
      if (user?.token == null) throw Exception("Unauthorized");

      return service.getChatHistory(user!.token!, bookingId);
    });

final chatControllerProvider =
    AsyncNotifierProvider.autoDispose<ChatController, void>(ChatController.new);

class ChatController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendMessage(int bookingId, String content) async {
    final service = ref.read(chatServiceProvider);
    final user = ref.read(userProvider);
    if (user?.token == null) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await service.sendMessage(
        user!.token!,
        SendMessageRequest(
          bookingId: bookingId,
          content: content,
          type: "TEXT",
        ),
      );
    });

    if (!state.hasError) {
      ref.invalidate(chatHistoryProvider(bookingId));
      ref.invalidate(chatRoomsProvider);
    }
  }

  Future<void> sendImage(int bookingId, File imageFile) async {
    final service = ref.read(chatServiceProvider);
    final user = ref.read(userProvider);
    if (user?.token == null) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await service.sendMessage(
        user!.token!,
        SendMessageRequest(bookingId: bookingId, content: "", type: "IMAGE"),
        imageFile: imageFile,
      );
    });

    if (!state.hasError) {
      ref.invalidate(chatHistoryProvider(bookingId));
      ref.invalidate(chatRoomsProvider);
    }
  }
}
