import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Stores this device's FCM token under users/{uid}/devices/{token}.
/// The Cloud Function fans broadcasts out by reading these subcollections.
class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<String>? _refreshSub;
  String? _currentUid;
  String? _currentToken;

  Future<void> registerForUser(String uid) async {
    _currentUid = uid;

    final token = await _fcm.getToken();
    if (token != null) {
      _currentToken = token;
      await _saveToken(uid, token);
    }

    _refreshSub?.cancel();
    _refreshSub = _fcm.onTokenRefresh.listen((newToken) async {
      if (_currentUid != uid) return;
      if (_currentToken != null && _currentToken != newToken) {
        await _db
            .collection('users')
            .doc(uid)
            .collection('devices')
            .doc(_currentToken)
            .delete();
      }
      _currentToken = newToken;
      await _saveToken(uid, newToken);
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(token)
        .set({
      'token': token,
      'platform': _platform(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unregister() async {
    final uid = _currentUid;
    final token = _currentToken;
    _refreshSub?.cancel();
    _refreshSub = null;
    _currentUid = null;
    _currentToken = null;
    if (uid != null && token != null) {
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('devices')
            .doc(token)
            .delete();
      } catch (_) {}
    }
  }

  String _platform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }
}
