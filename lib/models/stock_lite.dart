class StockLite {
  StockLite({
    required this.id,
    required this.designationProduit,
    this.refJpc,
    this.categorie,
    this.sousCategorie,
  });

  final String id;
  final String designationProduit;
  final String? refJpc;
  final String? categorie;
  final String? sousCategorie;

  String get label {
    final ref = (refJpc ?? '').trim();
    return ref.isNotEmpty ? '$designationProduit — Réf $ref' : designationProduit;
  }

  bool get isDiffuseur {
    final haystack =
        '${categorie ?? ''} ${sousCategorie ?? ''} $designationProduit'
            .toLowerCase();
    return haystack.contains('diffuseur');
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory StockLite.fromJson(Map<String, dynamic> m) {
    return StockLite(
      id: '${m['id']}',
      designationProduit: '${m['designation_produit'] ?? ''}',
      refJpc: _str(m['ref_jpc']),
      categorie: _str(m['categorie']),
      sousCategorie: _str(m['sous_categorie']),
    );
  }
}
