import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop.dart';

class ShopService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _shops =>
      _db.collection('shops');

  CollectionReference<Map<String, dynamic>> _followingCol(String uid) =>
      _db.collection('users').doc(uid).collection('following');

  Stream<List<Shop>> streamShops() {
    return _shops.snapshots().map((snap) =>
        snap.docs.map(Shop.fromDoc).toList(growable: false));
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
}
