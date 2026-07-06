class SortieHuileDiffuseur {
  SortieHuileDiffuseur({
    required this.equipementId,
    this.emplacement,
    this.typeDiffuseur,
    this.reference,
    this.senteur,
    this.stockId,
    this.refJpc,
    this.designation,
    required this.quantiteMl,
    this.source = 'contractuel',
  });

  final String equipementId;
  final String? emplacement;
  final String? typeDiffuseur;
  final String? reference;
  final String? senteur;
  final String? stockId;
  final String? refJpc;
  final String? designation;
  final double quantiteMl;
  final String source;

  bool get isManuel => source == 'manuel';
  bool get isSortieReelle => source == 'sortie';
  bool get isContractuel => source == 'contractuel';

  String get sourceLabel {
    switch (source) {
      case 'manuel':
        return 'Manuel';
      case 'sortie':
        return 'Sorti';
      case 'contractuel':
      default:
        return 'Contractuel';
    }
  }

  String get huileLabel {
    final s = (senteur ?? '').trim();
    if (s.isNotEmpty) return s;
    final d = (designation ?? '').trim();
    if (d.isNotEmpty) return d;
    final r = (refJpc ?? '').trim();
    if (r.isNotEmpty) return r;
    return 'Huile';
  }

  String get diffuseurLabel {
    final parts = <String>[];
    final type = (typeDiffuseur ?? '').trim();
    if (type.isNotEmpty) parts.add(type);
    final ref = (reference ?? '').trim();
    if (ref.isNotEmpty) parts.add(ref);
    final emp = (emplacement ?? '').trim();
    if (emp.isNotEmpty) parts.add(emp);
    if (parts.isNotEmpty) return parts.join(' · ');
    return 'Diffuseur';
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  factory SortieHuileDiffuseur.fromJson(Map<String, dynamic> m) {
    return SortieHuileDiffuseur(
      equipementId: '${m['equipement_id']}',
      emplacement: _str(m['emplacement']),
      typeDiffuseur: _str(m['type_diffuseur']),
      reference: _str(m['reference']),
      senteur: _str(m['senteur']),
      stockId: m['stock_id']?.toString(),
      refJpc: _str(m['ref_jpc']),
      designation: _str(m['designation']),
      quantiteMl: _num(m['quantite_ml']),
      source: _str(m['source']) ?? 'contractuel',
    );
  }
}

List<SortieHuileDiffuseur> parseSortieHuileParDiffuseur(dynamic raw) {
  final out = <SortieHuileDiffuseur>[];
  if (raw is List) {
    for (final e in raw) {
      if (e is Map) {
        out.add(SortieHuileDiffuseur.fromJson(Map<String, dynamic>.from(e)));
      }
    }
  }
  return out;
}
