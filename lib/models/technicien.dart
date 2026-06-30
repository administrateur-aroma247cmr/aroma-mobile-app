class Technicien {
  Technicien({
    required this.id,
    this.nom,
    this.idCollaborateur,
  });

  final String id;
  final String? nom;
  final String? idCollaborateur;

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory Technicien.fromJson(Map<String, dynamic> m) {
    return Technicien(
      id: '${m['id']}',
      nom: _str(m['nom']),
      idCollaborateur: m['id_collaborateur']?.toString(),
    );
  }
}
