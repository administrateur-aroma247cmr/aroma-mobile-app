import 'package:shared_preferences/shared_preferences.dart';

import '../utils/entity_scope.dart';

class EntityStore {
  Future<String?> read() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(entityStorageKey)?.trim();
    return raw != null && raw.isNotEmpty ? normalizeEntityCode(raw) : null;
  }

  Future<void> write(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(entityStorageKey, normalizeEntityCode(code));
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(entityStorageKey);
  }
}
