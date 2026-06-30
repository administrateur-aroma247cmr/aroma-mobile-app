/// Contact client (aligné `/api/contacts` CRM).
class ContactClient {
  ContactClient({
    required this.id,
    this.idTiers,
    this.idAgence,
    this.civilite,
    this.nom,
    this.prenom,
    this.poste,
    this.telephone,
    this.email,
    this.typeContact,
  });

  final String id;
  final String? idTiers;
  final String? idAgence;
  final String? civilite;
  final String? nom;
  final String? prenom;
  final String? poste;
  final String? telephone;
  final String? email;
  final String? typeContact;

  String get nomAffiche {
    final parts = [
      (civilite ?? '').trim(),
      (prenom ?? '').trim(),
      (nom ?? '').trim(),
    ].where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return '—';
  }

  String get listeLabel {
    final name = nomAffiche;
    final p = (poste ?? '').trim();
    if (name != '—' && p.isNotEmpty) return '$name — $p';
    return name != '—' ? name : (p.isNotEmpty ? p : '—');
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory ContactClient.fromJson(Map<String, dynamic> m) {
    return ContactClient(
      id: '${m['id']}',
      idTiers: m['id_tiers']?.toString(),
      idAgence: m['id_agence']?.toString(),
      civilite: _str(m['civilite']),
      nom: _str(m['nom']),
      prenom: _str(m['prenom']),
      poste: _str(m['poste']),
      telephone: _str(m['telephone']),
      email: _str(m['email']),
      typeContact: _str(m['type_contact']),
    );
  }
}
