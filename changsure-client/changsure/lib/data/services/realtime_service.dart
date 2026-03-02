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

    final rolePath = (role == RealtimeRole.technician)
        ? '/ws/technicians'
        : '/ws/customers';

    print("🔌 RealtimeService.connect() called");
    print("   role: $role");
    print("   path: $rolePath");
    print("   token: ${token.substring(0, 20)}...");

    Uri targetUri = Uri.parse(ApiConstants.baseUrl);

    String newScheme = targetUri.scheme;
    if (targetUri.scheme == 'https') {
      newScheme = 'wss';
    } else if (targetUri.scheme == 'http') {
      newScheme = 'ws';
    }

    final finalUri = targetUri.replace(
      scheme: newScheme,
      path: rolePath,
      queryParameters: {'token': token},
    );

    _channel = WebSocketChannel.connect(finalUri);

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
      cancelOnError: true,
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
