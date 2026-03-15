import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'package:changsure/core/constants/api_constants.dart';

enum RealtimeRole { technician, customer }

class RealtimeService {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  Stream<Map<String, dynamic>>? _broadcast;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream {
    _broadcast ??= _controller.stream;
    return _broadcast!;
  }

  bool get isConnected => _channel != null;

  void connect({required String token, required RealtimeRole role}) {
    disconnect();

    final rolePath = role == RealtimeRole.technician
        ? "technicians"
        : "customers";

    final uri = Uri.parse("${ApiConstants.wsBaseUrl}$rolePath?token=$token");

    print("🔌 WS connect → $uri");

    _channel = WebSocketChannel.connect(uri);

    _sub = _channel!.stream.listen(
      (event) {
        try {
          final decoded = jsonDecode(event.toString());
          if (decoded is Map<String, dynamic>) {
            _controller.add(decoded);
          } else {
            _controller.add({'type': 'RAW', 'data': event.toString()});
          }
        } catch (_) {
          _controller.add({'type': 'RAW', 'data': event.toString()});
        }
      },
      onError: (e) {
        _controller.add({'type': 'ERROR', 'message': e.toString()});
      },
      onDone: () {
        _controller.add({'type': 'CLOSED'});
      },
    );
  }

  void disconnect() {
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close(status.normalClosure);
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
