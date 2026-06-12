String fmtFcfa(num? value) {
  if (value == null) return '—';
  final n = value.round();
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  final formatted = buf.toString();
  return '${n < 0 ? '-$formatted' : formatted} F CFA';
}

String formatDateFr(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(iso.trim());
  if (m != null) {
    return '${m.group(3)}/${m.group(2)}/${m.group(1)}';
  }
  return iso;
}

String currentMonthIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}';
}

String monthLabelFr(String moisIso) {
  final parts = moisIso.split('-');
  if (parts.length < 2) return moisIso;
  const months = [
    '',
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  final m = int.tryParse(parts[1]);
  if (m == null || m < 1 || m > 12) return moisIso;
  return '${months[m]} ${parts[0]}';
}
