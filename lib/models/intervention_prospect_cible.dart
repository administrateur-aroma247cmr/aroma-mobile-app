class InterventionProspectCible {
  InterventionProspectCible({
    required this.key,
    required this.label,
    required this.nom,
    required this.sourceType,
    required this.sourceId,
    this.ville,
    this.idProspect,
  });

  final String key;
  final String label;
  final String nom;
  final String sourceType;
  final String sourceId;
  final String? ville;
  final String? idProspect;

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory InterventionProspectCible.fromJson(Map<String, dynamic> m) {
    return InterventionProspectCible(
      key: '${m['key']}',
      label: '${m['label'] ?? m['nom'] ?? ''}',
      nom: '${m['nom'] ?? ''}',
      sourceType: '${m['source_type'] ?? ''}',
      sourceId: '${m['source_id'] ?? ''}',
      ville: _str(m['ville']),
      idProspect: m['id_prospect']?.toString(),
    );
  }
}
