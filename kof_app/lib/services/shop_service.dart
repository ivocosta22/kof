import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop.dart';

class ShopService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _shops =>
      _db.collection('shops');

  CollectionReference<Map<String, dynamic>> _followingCol(String uid) =>
      _db.collection('users').doc(uid).collection('following');

  Stream<List<Shop>> streamShops({String? country}) {
    final query = country != null
        ? _shops.where('country', isEqualTo: country)
        : _shops as Query<Map<String, dynamic>>;
    return query.snapshots().map(
        (snap) => snap.docs.map(Shop.fromDoc).toList(growable: false));
  }

  Future<Shop?> getShop(String shopId) async {
    final doc = await _shops.doc(shopId).get();
    if (!doc.exists) return null;
    return Shop.fromDoc(doc);
  }

  Stream<Set<String>> streamFollowedShopIds(String uid) {
    return _followingCol(uid).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toSet(),
        );
  }

  Stream<List<Shop>> streamFollowedShops(String uid) async* {
    await for (final ids in streamFollowedShopIds(uid)) {
      if (ids.isEmpty) {
        yield const [];
        continue;
      }
      final chunks = <List<String>>[];
      final list = ids.toList();
      for (var i = 0; i < list.length; i += 10) {
        chunks.add(list.sublist(i, i + 10 > list.length ? list.length : i + 10));
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

  Future<bool> isFollowing(String uid, String shopId) async {
    final doc = await _followingCol(uid).doc(shopId).get();
    return doc.exists;
  }

  Future<void> followShop(String uid, String shopId) async {
    final batch = _db.batch();
    final payload = {'followedAt': FieldValue.serverTimestamp()};
    batch.set(_followingCol(uid).doc(shopId), payload);
    batch.set(_shops.doc(shopId).collection('followers').doc(uid), payload);
    await batch.commit();
  }

  Future<void> unfollowShop(String uid, String shopId) async {
    final batch = _db.batch();
    batch.delete(_followingCol(uid).doc(shopId));
    batch.delete(_shops.doc(shopId).collection('followers').doc(uid));
    await batch.commit();
  }

  /// Persist a computed review average + count back onto the shop document.
  /// Used by the reviews screen so the shop card / detail header on the map
  /// reflect the live rating instead of staying at whatever was last set on
  /// the kof_server platform panel.
  ///
  /// Only writes when the rounded average or the count actually differ from
  /// what's already on the doc — avoids spurious writes every time anyone
  /// opens the reviews screen.
  Future<void> syncRating(
    String shopId, {
    required double average,
    required int count,
  }) async {
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
