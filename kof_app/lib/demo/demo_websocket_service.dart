import 'dart:async';
import '../services/websocket_service.dart';
import 'demo_api_service.dart';

/// Demo-mode WebSocket: no real TCP connection.
/// Fires a `realtime_connected` event immediately, then simulates order
/// status progression: new → making (5 s) → ready (13 s).
class DemoWebSocketService extends WebSocketService {
  Timer? _timer;

  @override
  void connect(
    String serverUrl,
    void Function(Map<String, dynamic> message) onMessage, {
    void Function()? onDone,
    void Function(Object error)? onError,
  }) {
    disconnect();

    // Signal connected immediately.
    Future<void>.microtask(
      () => onMessage({'type': 'realtime_connected'}),
    );

    final orderId = DemoApiService.latestOrderId;
    if (orderId == null) return;

    _timer = Timer(const Duration(seconds: 5), () {
      onMessage({
        'type': 'order_status_changed',
        'payload': {'id': orderId, 'status': 'making'},
      });
      DemoApiService.updateOrderStatus(orderId, 'making');

      _timer = Timer(const Duration(seconds: 8), () {
        onMessage({
          'type': 'order_status_changed',
          'payload': {'id': orderId, 'status': 'ready'},
        });
        DemoApiService.updateOrderStatus(orderId, 'ready');
      });
    });
  }

  @override
  void disconnect() {
    _timer?.cancel();
    _timer = null;
  }
}
