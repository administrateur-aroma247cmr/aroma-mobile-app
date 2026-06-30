class ProspectLite {
  ProspectLite({
    required this.id,
    this.nom,
    this.prenom,
    this.societe,
  });

  final String id;
  final String? nom;
  final String? prenom;
  final String? societe;

  String get label {
    final parts = [(prenom ?? '').trim(), (nom ?? '').trim()]
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    final s = (societe ?? '').trim();
    return s.isNotEmpty ? s : 'Prospect';
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory ProspectLite.fromJson(Map<String, dynamic> m) {
    return ProspectLite(
      id: '${m['id']}',
      nom: _str(m['nom']),
      prenom: _str(m['prenom']),
      societe: _str(m['societe']),
    );
  }
}
