class DemandeRh {
  DemandeRh({
    required this.id,
    required this.idCollaborateur,
    required this.type,
    required this.dateDebut,
    required this.dateFin,
    this.motif,
    this.montant,
    this.statut,
    this.entityCode,
    this.dateReponse,
    this.reponseCommentaire,
  });

  final String id;
  final String idCollaborateur;
  final String type;
  final String dateDebut;
  final String dateFin;
  final String? motif;
  final double? montant;
  final String? statut;
  final String? entityCode;
  final String? dateReponse;
  final String? reponseCommentaire;

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  factory DemandeRh.fromJson(Map<String, dynamic> m) {
    return DemandeRh(
      id: '${m['id']}',
      idCollaborateur: '${m['id_collaborateur'] ?? ''}',
      type: '${m['type'] ?? ''}',
      dateDebut: '${m['date_debut'] ?? ''}',
      dateFin: '${m['date_fin'] ?? ''}',
      motif: m['motif'] is String ? m['motif'] as String : null,
      montant: _num(m['montant']),
      statut: m['statut'] is String ? m['statut'] as String : null,
      entityCode: m['entity_code'] is String ? m['entity_code'] as String : null,
      dateReponse:
          m['date_reponse'] is String ? m['date_reponse'] as String : null,
      reponseCommentaire: m['reponse_commentaire'] is String
          ? m['reponse_commentaire'] as String
          : null,
    );
  }
}

const rhDemandeTypes = [
  'Absence',
  'Avance de Paiement',
  'Maladie',
  'Congé',
];

String labelStatutDemande(String? statut) {
  return switch (statut) {
    'en_attente' => 'En attente',
    'approuve' => 'Approuvé',
    'approuve_paye' => 'Approuvé payé',
    'approuve_non_paye' => 'Approuvé non payé',
    'rejete' => 'Rejeté',
    'refuse' => 'Refusé',
    _ => statut ?? '—',
  };
}

String labelTypeDemande(String type) {
  return switch (type) {
    'Maladie' => 'Justificatif de maladie',
    'Congé' => 'Demande de congé',
    _ => type,
  };
}
