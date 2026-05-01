import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<String?> getCountry(String uid) async {
    final doc = await _userDoc(uid).get();
    return doc.data()?['country'] as String?;
  }

  Future<void> saveCountry(String uid, String country) async {
    await _userDoc(uid).set(
      {'country': country},
      SetOptions(merge: true),
    );
  }

  Future<String?> getPhone(String uid) async {
    final doc = await _userDoc(uid).get();
    return doc.data()?['phone'] as String?;
  }

  Future<void> savePhone(String uid, String phone) async {
    await _userDoc(uid).set(
      {'phone': phone.trim()},
      SetOptions(merge: true),
    );
  }
}
