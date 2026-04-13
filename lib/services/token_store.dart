import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _key = 'aroma_access_token';

  Future<String?> read() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key);
  }

  Future<void> write(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, token);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
