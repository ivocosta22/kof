import 'package:cloud_firestore/cloud_firestore.dart';
import '../demo/demo_mode.dart';

class UserService {
  FirebaseFirestore? __db;
  FirebaseFirestore get _db => __db ??= FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<String?> getCountry(String uid) async {
    if (kDemoMode) return null;
    final doc = await _userDoc(uid).get();
    return doc.data()?['country'] as String?;
  }

  Future<void> saveCountry(String uid, String country) async {
    if (kDemoMode) return;
    await _userDoc(uid).set(
      {'country': country},
      SetOptions(merge: true),
    );
  }

  Future<String?> getPhone(String uid) async {
    if (kDemoMode) return null;
    final doc = await _userDoc(uid).get();
    return doc.data()?['phone'] as String?;
  }

  Future<void> savePhone(String uid, String phone) async {
    if (kDemoMode) return;
    await _userDoc(uid).set(
      {'phone': phone.trim()},
      SetOptions(merge: true),
    );
  }
}
