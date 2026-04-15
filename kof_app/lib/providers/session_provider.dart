import 'package:flutter/foundation.dart';
import '../models/table_session.dart';

class SessionProvider extends ChangeNotifier {
  TableSession? _session;

  TableSession? get session => _session;
  bool get hasSession => _session != null;

  void setSession(TableSession session) {
    _session = session;
    notifyListeners();
  }

  void clearSession() {
    _session = null;
    notifyListeners();
  }
}
