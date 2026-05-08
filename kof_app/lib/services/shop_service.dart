import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../demo/demo_data.dart';
import '../demo/demo_mode.dart';
import '../models/shop.dart';

/// Guest follows are persisted locally on the device. Once the user signs in
/// or registers we offer to migrate them into Firestore under the new uid.
class _GuestFollowsStore {
  static const _key = 'kof_guest_followed_shops_v1';
  static final _ctrl = StreamController<Set<String>>.broadcast();

  static Future<Set<String>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  static Stream<Set<String>> stream() async* {
    yield await _read();
    yield* _ctrl.stream;
  }

  static Future<bool> contains(String shopId) async =>
      (await _read()).contains(shopId);

  static Future<void> add(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_key) ?? const <String>[]).toSet();
    if (set.add(shopId)) {
      await prefs.setStringList(_key, set.toList());
      _ctrl.add(set);
    }
  }

  static Future<void> remove(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_key) ?? const <String>[]).toSet();
    if (set.remove(shopId)) {
      await prefs.setStringList(_key, set.toList());
      _ctrl.add(set);
    }
  }

  static Future<int> count() async => (await _read()).length;

  static Future<List<String>> drain() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? const <String>[]).toList();
    await prefs.remove(_key);
    _ctrl.add(<String>{});
    return ids;
  }
}

class ShopService {
  // Lazy so Firebase is never accessed before initializeApp() in demo mode.
  FirebaseFirestore? __db;
  FirebaseFirestore get _db => __db ??= FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _shops =>
      _db.collection('shops');

  CollectionReference<Map<String, dynamic>> _followingCol(String uid) =>
      _db.collection('users').doc(uid).collection('following');

  Stream<List<Shop>> streamShops({String? country}) {
    if (kDemoMode) {
      final filtered = country != null
          ? DemoData.allShops.where((s) => s.country == country).toList()
          : DemoData.allShops;
      return Stream.value(filtered);
    }
    final query = country != null
        ? _shops.where('country', isEqualTo: country)
        : _shops as Query<Map<String, dynamic>>;
    return query.snapshots().map(
        (snap) => snap.docs.map(Shop.fromDoc).toList(growable: false));
  }

  Future<Shop?> getShop(String shopId) async {
    if (kDemoMode) {
      return DemoData.allShops.where((s) => s.id == shopId).firstOrNull;
    }
    final doc = await _shops.doc(shopId).get();
    if (!doc.exists) return null;
    return Shop.fromDoc(doc);
  }

  Stream<Set<String>> streamFollowedShopIds(String uid,
      {bool isGuest = false}) {
    // In demo mode, always use local storage regardless of account type.
    if (isGuest || kDemoMode) return _GuestFollowsStore.stream();
    return _followingCol(uid).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toSet(),
        );
  }

  Stream<List<Shop>> streamFollowedShops(String uid,
      {bool isGuest = false}) async* {
    await for (final ids in streamFollowedShopIds(uid, isGuest: isGuest)) {
      if (ids.isEmpty) {
        yield const [];
        continue;
      }
      // In demo mode, look up shops from DemoData — no Firestore needed.
      if (kDemoMode) {
        yield DemoData.allShops.where((s) => ids.contains(s.id)).toList();
        continue;
      }
      final chunks = <List<String>>[];
      final list = ids.toList();
      for (var i = 0; i < list.length; i += 10) {
        chunks.add(list.sublist(
            i, i + 10 > list.length ? list.length : i + 10));
      }
      final results = <Shop>[];
      for (final chunk in chunks) {
        final snap =
            await _shops.where(FieldPath.documentId, whereIn: chunk).get();
        results.addAll(snap.docs.map(Shop.fromDoc));
      }
      yield results;
    }
  }

  Future<bool> isFollowing(String uid, String shopId,
      {bool isGuest = false}) async {
    if (isGuest || kDemoMode) return _GuestFollowsStore.contains(shopId);
    final doc = await _followingCol(uid).doc(shopId).get();
    return doc.exists;
  }

  Future<void> followShop(String uid, String shopId,
      {bool isGuest = false}) async {
    if (isGuest || kDemoMode) {
      await _GuestFollowsStore.add(shopId);
      return;
    }
    final batch = _db.batch();
    final payload = {'followedAt': FieldValue.serverTimestamp()};
    batch.set(_followingCol(uid).doc(shopId), payload);
    batch.set(_shops.doc(shopId).collection('followers').doc(uid), payload);
    await batch.commit();
  }

  Future<void> unfollowShop(String uid, String shopId,
      {bool isGuest = false}) async {
    if (isGuest || kDemoMode) {
      await _GuestFollowsStore.remove(shopId);
      return;
    }
    final batch = _db.batch();
    batch.delete(_followingCol(uid).doc(shopId));
    batch.delete(_shops.doc(shopId).collection('followers').doc(uid));
    await batch.commit();
  }

  /// Number of shops the guest user is following locally. Used by the guest →
  /// account migration prompt.
  static Future<int> guestFollowedCount() => _GuestFollowsStore.count();

  /// Move every locally-followed shop into Firestore under [uid] and clear
  /// the local guest store. Best-effort: a failure on one shop won't roll
  /// back the others.
  Future<void> migrateGuestFollowsToUser(String uid) async {
    if (kDemoMode || uid.isEmpty) return;
    final ids = await _GuestFollowsStore.drain();
    if (ids.isEmpty) return;
    for (final shopId in ids) {
      try {
        await followShop(uid, shopId);
      } catch (_) {/* skip shops that fail (deleted, network blip, etc.) */}
    }
  }

  /// Drop the local guest follows without migrating. Used when the user
  /// declines the migration prompt so it doesn't keep firing.
  static Future<void> clearGuestFollows() => _GuestFollowsStore.drain();

  /// Persist a computed review average + count back onto the shop document.
  Future<void> syncRating(
    String shopId, {
    required double average,
    required int count,
  }) async {
    if (kDemoMode) return;
    final ref = _shops.doc(shopId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() ?? const {};
    final existingAvg = (data['rating'] as num?)?.toDouble();
    final existingCount = (data['ratingCount'] as num?)?.toInt();
    // Compare to one decimal place — that's the precision we display anyway.
    final rounded = double.parse(average.toStringAsFixed(1));
    if (existingAvg == rounded && existingCount == count) return;

    await ref.update({
      'rating': rounded,
      'ratingCount': count,
    });
  }
}
