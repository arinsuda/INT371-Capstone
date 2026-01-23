import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/data/services/realtime_service.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
});

final realtimeStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.stream;
});
