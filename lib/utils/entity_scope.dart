// Multi-entité : persistance + header API `X-Aroma-Entity` (aligné CRM web).

const entityStorageKey = 'aroma_entity_code';
const entityHeader = 'X-Aroma-Entity';
const entityScopeAll = 'ALL';

String normalizeEntityCode(String raw) {
  final upper = raw.trim().toUpperCase();
  return upper == 'CIV' ? 'CI' : upper;
}

bool isEntityScopeAll(String? code) {
  return normalizeEntityCode(code ?? '') == entityScopeAll;
}

bool canShowEntityScopeAll(
  List<String> entityCodes, {
  required bool canEntityScopeAllFlag,
}) {
  return canEntityScopeAllFlag && entityCodes.length > 1;
}

List<String> normalizeEntityCodes(dynamic raw) {
  if (raw is! List) return const [];
  final out = <String>{};
  for (final e in raw) {
    final s = e?.toString().trim();
    if (s != null && s.isNotEmpty) {
      out.add(normalizeEntityCode(s));
    }
  }
  final list = out.toList()..sort();
  return list;
}

/// Si la valeur stockée est absente ou non autorisée, repasse sur CM ou la 1re entité.
String? syncEntityWithAllowed({
  required String? stored,
  required List<String> allowed,
  required bool canEntityScopeAllFlag,
}) {
  if (allowed.isEmpty) return stored;
  final norm = normalizeEntityCodes(allowed);
  if (norm.isEmpty) return stored;

  final cur = stored != null ? normalizeEntityCode(stored) : null;

  if (cur == entityScopeAll) {
    if (canShowEntityScopeAll(
      norm,
      canEntityScopeAllFlag: canEntityScopeAllFlag,
    )) {
      return entityScopeAll;
    }
    return norm.contains('CM') ? 'CM' : norm.first;
  }

  if (cur != null && norm.contains(cur)) return cur;
  return norm.contains('CM') ? 'CM' : norm.first;
}

String entityDisplayLabel(String code, {Map<String, String>? labels}) {
  if (isEntityScopeAll(code)) return 'Tous les pays';
  final key = normalizeEntityCode(code);
  final fromApi = labels?[key];
  if (fromApi != null && fromApi.isNotEmpty) return fromApi;
  return switch (key) {
    'CM' => 'Cameroun',
    'CI' => "Côte d'Ivoire",
    _ => key,
  };
}
