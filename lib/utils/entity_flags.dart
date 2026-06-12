String? entityFlagEmoji(String? entityCode) {
  if (entityCode == null || entityCode.trim().isEmpty) return null;
  final key = entityCode.trim().toUpperCase();
  const map = {'CM': 'CM', 'CI': 'CI', 'CIV': 'CI'};
  final iso = map[key] ?? (key.length == 2 ? key : null);
  if (iso == null || iso.length != 2) return null;
  final a = iso.codeUnitAt(0) - 65;
  final b = iso.codeUnitAt(1) - 65;
  if (a < 0 || a > 25 || b < 0 || b > 25) return null;
  return String.fromCharCodes([0x1F1E6 + a, 0x1F1E6 + b]);
}
