import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bottom_nav_provider.dart';

final bottomSubPageHistoryProvider =
    StateNotifierProvider<BottomSubPageHistoryNotifier, List<SubPageConfig>>(
      (ref) => BottomSubPageHistoryNotifier(),
    );

class BottomSubPageHistoryNotifier extends StateNotifier<List<SubPageConfig>> {
  BottomSubPageHistoryNotifier() : super(const []);

  void push(SubPageConfig page) {
    state = [...state, page];
  }

  SubPageConfig? pop() {
    if (state.isEmpty) return null;

    final newState = [...state]..removeLast();
    state = newState;

    return newState.isNotEmpty ? newState.last : null;
  }

  void clear() => state = const [];
}
