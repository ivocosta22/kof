import 'package:flutter/foundation.dart';
import '../models/past_order.dart';
import '../services/order_history_service.dart';
import '../services/websocket_service.dart';

/// Holds the user's active orders (status: new/making/ready) so a floating
/// indicator can be shown anywhere in the app. Refreshed on demand by the
/// flows that change order state (placement, WS status updates, manual
/// pull-to-refresh).
class ActiveOrdersProvider extends ChangeNotifier {
  List<PastOrder> _orders = [];
  bool _loading = false;
  // Stack-counted suppression: screens that already display order info
  // (the order status screen, the my-orders screen) push this to hide the
  // floating bubble while they're visible, and pop it when they dispose.
  int _suppressionDepth = 0;
  // One WebSocket per unique shop URL we have active orders at — keeps the
  // floating bubble live without depending on which screen is open.
  final Map<String, WebSocketService> _sockets = {};

  List<PastOrder> get activeOrders =>
      _orders.where((o) => o.isActive).toList();

  bool get isLoading => _loading;
  bool get isSuppressed => _suppressionDepth > 0;

  void pushSuppression() {
    _suppressionDepth++;
    notifyListeners();
  }

  void popSuppression() {
    if (_suppressionDepth > 0) {
      _suppressionDepth--;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final service = OrderHistoryService();
      final orders = await service.getAll();
      _orders = await service.refreshFromServer(orders);
      _syncSockets();
    } catch (_) {
      // Keep previous list on failure — the indicator stays correct from the
      // last known good state.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Open a WebSocket for every shop with an active order; tear down sockets
  // for shops that no longer have one. Called after every refresh and after
  // any incoming status change (since a "completed" status might mean we no
  // longer need to listen to that shop).
  void _syncSockets() {
    final activeUrls = activeOrders
        .map((o) => o.serverUrl)
        .where((u) => u.isNotEmpty)
        .toSet();

    // Drop sockets we no longer need.
    for (final url in _sockets.keys.toList()) {
      if (!activeUrls.contains(url)) {
        _sockets[url]?.disconnect();
        _sockets.remove(url);
      }
    }

    // Open sockets for shops we don't have one for yet.
    for (final url in activeUrls) {
      if (_sockets.containsKey(url)) continue;
      final ws = WebSocketService();
      _sockets[url] = ws;
      ws.connect(
        url,
        _onWsMessage,
        onDone: () => _onSocketClosed(url),
        onError: (_) => _onSocketClosed(url),
      );
    }
  }

  void _onSocketClosed(String url) {
    // Drop the entry so the next refresh() can attempt a reconnect cleanly.
    _sockets.remove(url);
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    if (msg['type'] != 'order_status_changed') return;
    final payload = msg['payload'] as Map<String, dynamic>?;
    if (payload == null) return;

    final id = payload['id'] as int?;
    final newStatus = payload['status'] as String?;
    if (id == null || newStatus == null) return;

    final idx = _orders.indexWhere((o) => o.orderId == id);
    if (idx < 0) return;
    if (_orders[idx].status == newStatus) return;

    _orders[idx].status = newStatus;
    // Persist so My Orders + the bubble stay in agreement on next read.
    OrderHistoryService().updateStatus(id, newStatus);
    // The active set may have shrunk (e.g. moved to completed) — close any
    // sockets we no longer need.
    _syncSockets();
    notifyListeners();
  }

  // Reset all in-memory state and tear down sockets. Call on logout so the
  // next user (or guest session) doesn't briefly see the previous account's
  // active orders.
  void clear() {
    for (final ws in _sockets.values) {
      ws.disconnect();
    }
    _sockets.clear();
    _orders = [];
    _suppressionDepth = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ws in _sockets.values) {
      ws.disconnect();
    }
    _sockets.clear();
    super.dispose();
  }
}
