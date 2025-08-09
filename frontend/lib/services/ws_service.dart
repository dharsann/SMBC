import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  void connect(String userId) {
    final url = '${AppConfig.wsBaseUrl}/ws/$userId';
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  Stream<Map<String, dynamic>> get stream async* {
    if (_channel == null) {
      throw StateError('WebSocket not connected');
    }
    await for (final data in _channel!.stream) {
      if (data is String) {
        try {
          yield jsonDecode(data) as Map<String, dynamic>;
        } catch (_) {
          // ignore
        }
      }
    }
  }

  void send(String text) {
    _channel?.sink.add(text);
  }

  void close() {
    _channel?.sink.close();
    _channel = null;
  }
}