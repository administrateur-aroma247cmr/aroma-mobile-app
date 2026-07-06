// Checklists rapport terrain par type d'intervention (aligné backend CRM).

const extraKey = 'extra';
const extraKeyPrefix = 'extra_';
const actionKeyPrefix = 'action_';

const refillTemplate = 'refill';
const vdcTemplate = 'vdc';
const maintenanceTemplate = 'maintenance';

class RapportCheckItem {
  const RapportCheckItem({
    required this.key,
    required this.label,
    this.required = true,
    this.numeric = false,
    this.numericPlaceholder,
    this.repeatable = false,
  });

  final String key;
  final String label;
  final bool required;
  final bool numeric;
  final String? numericPlaceholder;
  final bool repeatable;
}

String normalizeRapportTemplate(String? typeIntervention) {
  final t = (typeIntervention ?? '').trim().toUpperCase();
  if (t == 'VDC' || t.startsWith('VISITE')) return vdcTemplate;
  if (t == 'MAINTENANCE' || t == 'MT') return maintenanceTemplate;
  return refillTemplate;
}

List<RapportCheckItem> _withExtra(List<RapportCheckItem> items) => [
      ...items,
      const RapportCheckItem(
        key: extraKey,
        label: 'Photo supplémentaire',
        required: false,
        repeatable: true,
      ),
    ];

final _refillItems = _withExtra(const [
  RapportCheckItem(key: 'nettoyage_alcool', label: 'Nettoyage à l’alcool'),
  RapportCheckItem(
    key: 'position',
    label: 'Photo grand angle — positionnement du diffuseur',
  ),
  RapportCheckItem(
    key: 'reservoir_ouvert',
    label: 'Photo diffuseur — réservoir ouvert (huile restante)',
  ),
  RapportCheckItem(
    key: 'pesee_etat',
    label: 'Photo pesée bouteille en l’état',
    numeric: true,
    numericPlaceholder: 'Poids (g)',
  ),
  RapportCheckItem(
    key: 'pesee_recharge',
    label: 'Photo pesée avec la recharge (poids mis en avant)',
    numeric: true,
    numericPlaceholder: 'Poids (g)',
  ),
  RapportCheckItem(
    key: 'programmation',
    label: 'Photo programmation ou programmation écrite',
  ),
  RapportCheckItem(
    key: 'reservoir_plein',
    label: 'Photo réservoir plein dans l’appareil',
  ),
  RapportCheckItem(
    key: 'ferme',
    label: 'Photo diffuseur fermé et remis à sa place',
  ),
]);

final _vdcItems = _withExtra(const [
  RapportCheckItem(
    key: 'arrivee',
    label: 'Photo de l’appareil à l’arrivée',
  ),
  RapportCheckItem(
    key: 'programmation',
    label: 'Photo de la programmation',
  ),
  RapportCheckItem(
    key: 'reservoir',
    label: 'Photo du réservoir dans l’appareil',
  ),
  RapportCheckItem(
    key: 'depart',
    label: 'Photo de l’appareil au départ',
  ),
]);

final _maintenanceItems = _withExtra([
  RapportCheckItem(
    key: 'arrivee',
    label: 'Photo de l’appareil à l’arrivée chez le client',
  ),
  RapportCheckItem(
    key: 'programmation',
    label: 'Photo de la programmation',
  ),
  RapportCheckItem(key: 'reservoir', label: 'Photo du réservoir'),
  RapportCheckItem(
    key: 'action',
    label: 'Photos des actions réalisées',
    repeatable: true,
  ),
  RapportCheckItem(key: 'pesee_avant', label: 'Photo pesée avant'),
  RapportCheckItem(key: 'pesee_apres', label: 'Photo pesée après'),
  RapportCheckItem(
    key: 'reservoir_depart',
    label: 'Photo du réservoir au départ',
  ),
]);

List<RapportCheckItem> diffuseurChecklistForType(String? typeIntervention) {
  switch (normalizeRapportTemplate(typeIntervention)) {
    case vdcTemplate:
      return _vdcItems;
    case maintenanceTemplate:
      return _maintenanceItems;
    default:
      return _refillItems;
  }
}

/// Rétrocompat — checklist Refill historique.
List<RapportCheckItem> get diffuseurCheckItems => _refillItems;

bool isActionKey(String key) {
  final m = RegExp(r'^action_(\d+)$').firstMatch(key.trim());
  return m != null;
}

int? actionIndexFromKey(String key) {
  final m = RegExp(r'^action_(\d+)$').firstMatch(key.trim());
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

String actionLabelForKey(String key) {
  final n = actionIndexFromKey(key);
  return n != null ? 'Action réalisée $n' : 'Action réalisée';
}

List<String> actionKeysSorted(Iterable<String> keys) {
  final list = keys.where(isActionKey).toList();
  list.sort((a, b) {
    final ia = actionIndexFromKey(a) ?? 0;
    final ib = actionIndexFromKey(b) ?? 0;
    return ia.compareTo(ib);
  });
  return list;
}

String nextActionKey(Iterable<String> existingKeys) {
  var max = 0;
  for (final k in existingKeys) {
    final n = actionIndexFromKey(k);
    if (n != null && n > max) max = n;
  }
  return '$actionKeyPrefix${max + 1}';
}

List<RapportCheckItem> fixedChecklistItems(List<RapportCheckItem> checklist) =>
    checklist.where((i) => !i.repeatable).toList();

List<RapportCheckItem> requiredPhotoItems(List<RapportCheckItem> checklist) =>
    checklist.where((i) => i.required && !i.repeatable).toList();

bool isExtraKey(String key) {
  final k = key.trim();
  if (k == extraKey) return true;
  return RegExp(r'^extra_(\d+)$').hasMatch(k);
}

int? extraIndexFromKey(String key) {
  final k = key.trim();
  if (k == extraKey) return 1;
  final m = RegExp(r'^extra_(\d+)$').firstMatch(k);
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

String extraLabelForKey(String key) {
  final n = extraIndexFromKey(key);
  if (n == null) return 'Photo supplémentaire';
  if (n == 1) return 'Photo supplémentaire';
  return 'Photo supplémentaire $n';
}

List<String> extraKeysSorted(Iterable<String> keys) {
  final list = keys.where(isExtraKey).toList();
  list.sort((a, b) {
    final ia = extraIndexFromKey(a) ?? 0;
    final ib = extraIndexFromKey(b) ?? 0;
    return ia.compareTo(ib);
  });
  return list;
}

String nextExtraKey(Iterable<String> existingKeys) {
  var max = 0;
  for (final k in existingKeys) {
    final n = extraIndexFromKey(k);
    if (n != null && n > max) max = n;
  }
  return '$extraKeyPrefix${max + 1}';
}

bool checklistHasRepeatableExtras(List<RapportCheckItem> checklist) =>
    checklist.any((i) => i.key == extraKey && i.repeatable);

bool checklistHasRepeatableActions(List<RapportCheckItem> checklist) =>
    checklist.any((i) => i.key == 'action' && i.repeatable);

String? checklistLabel(List<RapportCheckItem> checklist, String key) {
  if (isActionKey(key)) return actionLabelForKey(key);
  if (isExtraKey(key)) return extraLabelForKey(key);
  for (final item in checklist) {
    if (item.key == key) return item.label;
  }
  return null;
}
