import 'package:flutter/foundation.dart';

import '../services/aroma_api.dart';
import '../services/token_store.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({TokenStore? tokenStore})
      : _tokenStore = tokenStore ?? TokenStore() {
    _wireApi();
  }

  final TokenStore _tokenStore;
  late AromaApi _api;

  AromaApi get api => _api;

  String? _token;
  bool _loading = false;
  bool _initialized = false;
  String? _error;
  bool _mustChangePassword = false;
  Map<String, dynamic>? _me;

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get loading => _loading;
  bool get initialized => _initialized;
  String? get lastError => _error;
  bool get mustChangePassword => _mustChangePassword;
  Map<String, dynamic>? get me => _me;

  void _wireApi() {
    _api = AromaApi(getToken: () => _token);
  }

  Future<void> initialize() async {
    _token = await _tokenStore.read();
    _wireApi();
    if (isAuthenticated) {
      try {
        _me = await _api.me();
      } catch (_) {
        _token = null;
        await _tokenStore.clear();
        _wireApi();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.login(email: email, password: password);
      _token = data['access_token'] as String?;
      _mustChangePassword = data['must_change_password'] == true;
      if (_token != null) {
        await _tokenStore.write(_token!);
        _wireApi();
        try {
          _me = await _api.me();
        } catch (_) {
          _me = null;
        }
      }
      _loading = false;
      notifyListeners();
      return isAuthenticated;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _me = null;
    _mustChangePassword = false;
    await _tokenStore.clear();
    _wireApi();
    notifyListeners();
  }

  Future<void> refreshMe() async {
    if (!isAuthenticated) return;
    try {
      _me = await _api.me();
      notifyListeners();
    } catch (_) {}
  }
}
