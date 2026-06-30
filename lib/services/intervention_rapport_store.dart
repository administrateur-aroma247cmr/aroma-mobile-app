import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/intervention_rapport_draft.dart';

/// Persistance locale des brouillons de rapport (aligné web : pas d’API dédiée).
class InterventionRapportStore {
  InterventionRapportStore._();

  static const _prefix = 'intervention_rapport_draft_';

  static Future<InterventionRapportDraft?> load(String interventionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$interventionId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return InterventionRapportDraft.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<void> save(InterventionRapportDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix${draft.interventionId}',
      jsonEncode(draft.toJson()),
    );
  }

  static Future<void> delete(String interventionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$interventionId');
  }
}
