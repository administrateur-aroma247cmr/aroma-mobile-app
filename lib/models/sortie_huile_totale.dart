class SortieHuileTotale {
  SortieHuileTotale({
    this.senteur,
    this.refJpc,
    this.designation,
    required this.quantiteMl,
    this.source = 'sortie',
  });

  final String? senteur;
  final String? refJpc;
  final String? designation;
  final double quantiteMl;
  final String source;

  String get label {
    final s = (senteur ?? '').trim();
    if (s.isNotEmpty) return s;
    final d = (designation ?? '').trim();
    if (d.isNotEmpty) return d;
    final r = (refJpc ?? '').trim();
    if (r.isNotEmpty) return r;
    return 'Huile';
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  factory SortieHuileTotale.fromJson(Map<String, dynamic> m) {
    return SortieHuileTotale(
      senteur: _str(m['senteur']),
      refJpc: _str(m['ref_jpc']),
      designation: _str(m['designation']),
      quantiteMl: _num(m['quantite_ml']),
      source: _str(m['source']) ?? 'sortie',
    );
  }
}

List<SortieHuileTotale> parseSortieHuileTotale(dynamic raw) {
  final out = <SortieHuileTotale>[];
  if (raw is List) {
    for (final e in raw) {
      if (e is Map) {
        out.add(SortieHuileTotale.fromJson(Map<String, dynamic>.from(e)));
      }
    }
  }
  return out.where((l) => l.quantiteMl > 0).toList();
}

String? parseSortieHuileMode(dynamic raw) {
  if (raw is! String) return null;
  final v = raw.trim().toLowerCase();
  if (v == 'total' || v == 'diffuseur' || v == 'contractuel') return v;
  return null;
}
