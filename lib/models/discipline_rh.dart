class DisciplineRh {
  DisciplineRh({
    required this.id,
    required this.idCollaborateur,
    required this.type,
    required this.date,
    this.entityCode,
    this.motif,
    this.decision,
    this.typeExplication,
    this.descriptionProbleme,
    this.impactPaie = false,
    this.justification,
    this.documents = const [],
    this.lettreDocumentPath,
    this.lettreDocumentName,
    this.status,
  });

  final String id;
  final String idCollaborateur;
  final String type;
  final String date;
  final String? entityCode;
  final String? motif;
  final String? decision;
  final String? typeExplication;
  final String? descriptionProbleme;
  final bool impactPaie;
  final String? justification;
  final List<Map<String, dynamic>> documents;
  final String? lettreDocumentPath;
  final String? lettreDocumentName;
  final String? status;

  factory DisciplineRh.fromJson(Map<String, dynamic> m) {
    final docsRaw = m['documents'];
    final docs = <Map<String, dynamic>>[];
    if (docsRaw is List) {
      for (final d in docsRaw) {
        if (d is Map) {
          docs.add(Map<String, dynamic>.from(d));
        }
      }
    }
    return DisciplineRh(
      id: '${m['id']}',
      idCollaborateur: '${m['id_collaborateur'] ?? ''}',
      type: '${m['type'] ?? ''}',
      date: '${m['date'] ?? ''}',
      entityCode:
          m['entity_code'] is String ? m['entity_code'] as String : null,
      motif: m['motif'] is String ? m['motif'] as String : null,
      decision: m['decision'] is String ? m['decision'] as String : null,
      typeExplication: m['type_explication'] is String
          ? m['type_explication'] as String
          : null,
      descriptionProbleme: m['description_probleme'] is String
          ? m['description_probleme'] as String
          : null,
      impactPaie: m['impact_paie'] == true,
      justification:
          m['justification'] is String ? m['justification'] as String : null,
      documents: docs,
      lettreDocumentPath: m['lettre_document_path'] is String
          ? m['lettre_document_path'] as String
          : null,
      lettreDocumentName: m['lettre_document_name'] is String
          ? m['lettre_document_name'] as String
          : null,
      status: m['status'] is String ? m['status'] as String : null,
    );
  }
}

const disciplineTypes = [
  'avertissement',
  'blame',
  'mise_a_pied',
  'licenciement',
  'demande_explication',
];

String labelTypeDiscipline(String type) => switch (type) {
      'avertissement' => 'Avertissement',
      'blame' => 'Blâme',
      'mise_a_pied' => 'Mise à pied',
      'licenciement' => 'Licenciement',
      'demande_explication' => "Demande d'explication",
      _ => type,
    };

String labelStatutDiscipline(String? statut) => switch (statut) {
      'brouillon' => 'Brouillon',
      'en_cours' => 'En cours',
      'valide' => 'Validé',
      'rejete' => 'Rejeté',
      _ => statut ?? '—',
    };

String disciplineTypeExplicationLabel(DisciplineRh d) {
  if (d.typeExplication != null && d.typeExplication!.trim().isNotEmpty) {
    return d.typeExplication!.trim();
  }
  final desc = d.descriptionProbleme?.trim();
  if (desc == null || desc.isEmpty) return '—';
  return desc.length > 48 ? '${desc.substring(0, 48)}…' : desc;
}
