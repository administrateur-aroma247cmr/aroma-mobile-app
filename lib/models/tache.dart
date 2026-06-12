class Tache {
  Tache({
    required this.id,
    required this.nomTache,
    this.description,
    this.dateButoire,
    this.createdAt,
    this.statut,
    this.priorite,
    this.collaborateurId,
    this.collaborateurIds = const [],
    this.superviseurId,
    this.clientId,
    this.estSelectionnee,
    this.dateSelection,
    this.dateTerminee,
    this.categorie,
    this.createdBy,
  });

  final String id;
  final String nomTache;
  final String? description;
  final String? dateButoire;
  final String? createdAt;
  final String? statut;
  final String? priorite;
  final String? collaborateurId;
  final List<String> collaborateurIds;
  final String? superviseurId;
  final String? clientId;
  final bool? estSelectionnee;
  final String? dateSelection;
  final String? dateTerminee;
  final String? categorie;
  final String? createdBy;

  bool get isTerminee => statut == 'Terminé';
  bool get isSelectionnee => estSelectionnee == true;

  factory Tache.fromJson(Map<String, dynamic> m) {
    final rawIds = m['collaborateur_ids'];
    final ids = <String>[];
    if (rawIds is List) {
      for (final e in rawIds) {
        final s = e?.toString().trim();
        if (s != null && s.isNotEmpty) ids.add(s);
      }
    }
    return Tache(
      id: '${m['id']}',
      nomTache: '${m['nom_tache'] ?? ''}',
      description: m['description'] is String ? m['description'] as String : null,
      dateButoire: m['date_butoire'] is String ? m['date_butoire'] as String : null,
      createdAt: m['created_at'] is String ? m['created_at'] as String : null,
      statut: m['statut'] is String ? m['statut'] as String : null,
      priorite: m['priorite'] is String ? m['priorite'] as String : null,
      collaborateurId:
          m['collaborateur_id']?.toString().trim().isNotEmpty == true
              ? m['collaborateur_id'].toString()
              : null,
      collaborateurIds: ids,
      superviseurId:
          m['superviseur_id']?.toString().trim().isNotEmpty == true
              ? m['superviseur_id'].toString()
              : null,
      clientId: m['client_id']?.toString().trim().isNotEmpty == true
          ? m['client_id'].toString()
          : null,
      estSelectionnee: m['est_selectionnee'] == true,
      dateSelection:
          m['date_selection'] is String ? m['date_selection'] as String : null,
      dateTerminee:
          m['date_terminee'] is String ? m['date_terminee'] as String : null,
      categorie: m['categorie'] is String ? m['categorie'] as String : null,
      createdBy: m['created_by'] is String ? m['created_by'] as String : null,
    );
  }
}

class CollaborateurLite {
  CollaborateurLite({
    required this.id,
    required this.prenom,
    required this.nom,
  });

  final String id;
  final String prenom;
  final String nom;

  String get fullName => '$prenom $nom'.trim();

  factory CollaborateurLite.fromJson(Map<String, dynamic> m) {
    return CollaborateurLite(
      id: '${m['id']}',
      prenom: '${m['prenom'] ?? ''}',
      nom: '${m['nom'] ?? ''}',
    );
  }
}
