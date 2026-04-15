import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  void connect(
    String serverUrl,
    void Function(Map<String, dynamic> message) onMessage, {
    void Function()? onDone,
    void Function(Object error)? onError,
  }) {
    disconnect();

    final wsUrl = serverUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _subscription = _channel!.stream.listen(
      (data) {
        try {
          final msg = jsonDecode(data as String) as Map<String, dynamic>;
          onMessage(msg);
        } catch (_) {}
      },
      onDone: onDone,
      onError: onError,
      cancelOnError: false,
    );
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }
}
