/// Ligne de matériel sorti (agrégée depuis les mouvements stock intervention).
class MaterielSortieLigne {
  MaterielSortieLigne({
    required this.id,
    this.stockId,
    this.refJpc,
    this.designationProduit,
    this.unite,
    required this.quantite,
    this.senteur,
  });

  final String id;
  final String? stockId;
  final String? refJpc;
  final String? designationProduit;
  final String? unite;
  final double quantite;
  final String? senteur;

  String get label {
    final des = (designationProduit ?? '').trim();
    if (des.isNotEmpty) return des;
    final ref = (refJpc ?? '').trim();
    if (ref.isNotEmpty) return ref;
    return 'Produit';
  }

  String get refAffiche => (refJpc ?? '').trim();

  String get quantiteLabel {
    final u = (unite ?? 'ml').trim();
    final q = quantite;
    final qStr = q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(1);
    return '$qStr $u';
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  factory MaterielSortieLigne.fromJson(Map<String, dynamic> m) {
    return MaterielSortieLigne(
      id: '${m['id']}',
      stockId: m['stock_id']?.toString(),
      refJpc: _str(m['ref_jpc']),
      designationProduit: _str(m['designation_produit']),
      unite: _str(m['unite']),
      quantite: _num(m['quantite']),
      senteur: _str(m['senteur']),
    );
  }
}

List<MaterielSortieLigne> parseMaterielSortie(dynamic raw) {
  final out = <MaterielSortieLigne>[];
  if (raw is List) {
    for (final e in raw) {
      if (e is Map) {
        out.add(MaterielSortieLigne.fromJson(Map<String, dynamic>.from(e)));
      }
    }
  }
  return out.where((l) => l.quantite > 0).toList();
}
