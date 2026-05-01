import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../navigation.dart';
import '../screens/shop_detail_screen.dart';
import '../services/notifications_store.dart';
import '../services/shop_service.dart';

/// In-memory mirror of the persistent NotificationsStore for the current
/// user. Subscribes to Firebase Messaging streams once on creation:
///
/// - [FirebaseMessaging.onMessage] — push received while app is foregrounded
/// - [FirebaseMessaging.onMessageOpenedApp] — user tapped a notification that
///   was sitting in the system tray, bringing the app to the foreground
/// - [FirebaseMessaging.instance.getInitialMessage] — user tapped a
///   notification that cold-started the app
///
/// Background-only deliveries that the user never taps aren't captured —
/// that's standard FCM behaviour on Android.
class NotificationsProvider extends ChangeNotifier {
  List<NotificationItem> _items = [];
  String? _currentUserKey;
  bool _fcmHooked = false;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  // Holds the cold-start message until auth is established so it gets stored
  // under the correct user key instead of 'guest'.
  RemoteMessage? _pendingInitialMessage;

  List<NotificationItem> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.read).length;

  /// Hook the FCM streams. Idempotent — safe to call from `update` of a
  /// ChangeNotifierProxyProvider that fires on every Auth notification.
  void hookFcm() {
    if (_fcmHooked) return;
    _fcmHooked = true;

    _onMessageSub = FirebaseMessaging.onMessage.listen(_onRemote);
    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _onRemote(msg);
      _navigateToShop(msg);
    });

    // Cold-start: app launched by tapping a notification while terminated.
    // Auth may not be set yet, so store it and process once onAuthChanged
    // fires with a real user ID.
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg == null) return;
      if (_currentUserKey != null && _currentUserKey != 'guest') {
        _onRemote(msg);
        _navigateToShop(msg);
      } else {
        _pendingInitialMessage = msg;
      }
    });
  }

  void _onRemote(RemoteMessage msg) {
    final notif = msg.notification;
    final title = notif?.title ?? '';
    final body = notif?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final id = msg.messageId ??
        '${msg.data['shopId'] ?? ''}_${msg.data['broadcastId'] ?? ''}_'
            '${msg.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

    final item = NotificationItem(
      id: id,
      title: title,
      body: body,
      data: Map<String, String>.from(msg.data.map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      )),
      receivedAt: msg.sentTime ?? DateTime.now(),
    );

    _record(item);
  }

  Future<void> _navigateToShop(RemoteMessage msg) async {
    final shopId = msg.data['shopId'] as String?;
    if (shopId == null || shopId.isEmpty) return;

    final shop = await ShopService().getShop(shopId);
    if (shop == null) return;

    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;

    nav.push(MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)));
  }

  Future<void> _record(NotificationItem item) async {
    // Insert at the top, dedupe by id, and persist.
    _items.removeWhere((n) => n.id == item.id);
    _items.insert(0, item);
    notifyListeners();
    await NotificationsStore().save(item);
  }

  Future<void> refresh() async {
    _items = await NotificationsStore().getAll();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    var changed = false;
    for (final n in _items) {
      if (!n.read) {
        n.read = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      await NotificationsStore().markAllRead();
    }
  }

  Future<void> clearAll() async {
    _items = [];
    notifyListeners();
    await NotificationsStore().clear();
  }

  /// Auth scope sync. Same shape as ActiveOrdersProvider.onAuthChanged so
  /// the proxy provider in main.dart can simply chain both.
  void onAuthChanged(String? userId) {
    final next = (userId == null || userId.isEmpty) ? 'guest' : userId;
    if (_currentUserKey == next) return;
    _currentUserKey = next;

    NotificationsStore.setCurrentUser(userId);
    _items = [];
    notifyListeners();
    refresh().then((_) {
      // Process any cold-start notification that arrived before auth was ready.
      final pending = _pendingInitialMessage;
      if (pending != null && _currentUserKey != 'guest') {
        _pendingInitialMessage = null;
        _onRemote(pending);
        _navigateToShop(pending);
      }
    });
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();
    super.dispose();
  }
}
