class Intervention {
  Intervention({
    required this.id,
    this.ref,
    this.sujet,
    this.description,
    this.typeIntervention,
    this.site,
    this.siteNom,
    this.ville,
    this.clientNom,
    this.technicienNom,
    this.dateIntervention,
    this.etat,
    this.auteur,
  });

  final String id;
  final String? ref;
  final String? sujet;
  final String? description;
  final String? typeIntervention;
  final String? site;
  final String? siteNom;
  final String? ville;
  final String? clientNom;
  final String? technicienNom;
  final String? dateIntervention;
  final String? etat;
  final String? auteur;

  String get titreAffiche {
    final s = (sujet ?? '').trim();
    if (s.isNotEmpty) return s;
    final r = (ref ?? '').trim();
    if (r.isNotEmpty) return r;
    return 'Intervention';
  }

  String get siteAffiche {
    final sn = (siteNom ?? '').trim();
    if (sn.isNotEmpty) return sn;
    return (site ?? '').trim();
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory Intervention.fromJson(Map<String, dynamic> m) {
    return Intervention(
      id: '${m['id']}',
      ref: _str(m['ref']),
      sujet: _str(m['sujet']),
      description: _str(m['description']),
      typeIntervention: _str(m['type_intervention']),
      site: _str(m['site']),
      siteNom: _str(m['site_nom']),
      ville: _str(m['ville']),
      clientNom: _str(m['client_nom']),
      technicienNom: _str(m['technicien_nom']),
      dateIntervention: _str(m['date_intervention']),
      etat: _str(m['etat']) ?? _str(m['etat_app']),
      auteur: _str(m['auteur']),
    );
  }
}

class InterventionsListResult {
  InterventionsListResult({required this.items, required this.total});

  final List<Intervention> items;
  final int total;

  factory InterventionsListResult.fromJson(Map<String, dynamic> m) {
    final raw = m['items'];
    final items = <Intervention>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(Intervention.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return InterventionsListResult(
      items: items,
      total: (m['total'] as num?)?.toInt() ?? items.length,
    );
  }
}

class ExperienceAdc {
  ExperienceAdc({
    required this.id,
    this.clientName,
    this.siteName,
    this.datePlanifiee,
    this.dateAppel,
    this.statut,
    this.ressenti,
    this.commentaire,
    this.interventionRef,
  });

  final String id;
  final String? clientName;
  final String? siteName;
  final String? datePlanifiee;
  final String? dateAppel;
  final String? statut;
  final String? ressenti;
  final String? commentaire;
  final String? interventionRef;

  String get titreAffiche {
    final c = (clientName ?? '').trim();
    if (c.isNotEmpty) return c;
    return 'Appel de courtoisie';
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory ExperienceAdc.fromJson(Map<String, dynamic> m) {
    return ExperienceAdc(
      id: '${m['id']}',
      clientName: _str(m['client_name']),
      siteName: _str(m['site_name']),
      datePlanifiee: _str(m['date_planifiee']),
      dateAppel: _str(m['date_appel']),
      statut: _str(m['statut']),
      ressenti: _str(m['ressenti']),
      commentaire: _str(m['commentaire']),
      interventionRef: _str(m['intervention_ref']),
    );
  }
}

class TransportIntervention {
  TransportIntervention({
    required this.id,
    this.dateTransport,
    this.ville,
    this.raisonDeplacement,
    this.montantTotal,
    this.technicienNom,
    this.pointsCount = 0,
  });

  final String id;
  final String? dateTransport;
  final String? ville;
  final String? raisonDeplacement;
  final double? montantTotal;
  final String? technicienNom;
  final int pointsCount;

  String get titreAffiche {
    final r = (raisonDeplacement ?? '').trim();
    if (r.isNotEmpty) return r;
    final v = (ville ?? '').trim();
    if (v.isNotEmpty) return 'Transport · $v';
    return 'Fiche transport';
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory TransportIntervention.fromJson(Map<String, dynamic> m) {
    final rawPoints = m['points'];
    var count = 0;
    if (rawPoints is List) count = rawPoints.length;

    return TransportIntervention(
      id: '${m['id']}',
      dateTransport: _str(m['date_transport']),
      ville: _str(m['ville']),
      raisonDeplacement: _str(m['raison_deplacement']),
      montantTotal: _num(m['montant_total']),
      technicienNom: _str(m['technicien_nom']),
      pointsCount: count,
    );
  }
}

class Reparation {
  Reparation({
    required this.id,
    required this.panne,
    required this.statut,
    this.reference,
    this.descriptionProbleme,
    this.clientNom,
    this.prospectNom,
    this.technicienNom,
    this.typeDiffuseur,
    this.referenceDiffuseur,
  });

  final String id;
  final String? reference;
  final String panne;
  final String? descriptionProbleme;
  final String statut;
  final String? clientNom;
  final String? prospectNom;
  final String? technicienNom;
  final String? typeDiffuseur;
  final String? referenceDiffuseur;

  String get titreAffiche {
    final r = (reference ?? '').trim();
    if (r.isNotEmpty) return r;
    return panne.trim().isNotEmpty ? panne.trim() : 'Réparation';
  }

  String get clientAffiche {
    final c = (clientNom ?? '').trim();
    if (c.isNotEmpty) return c;
    return (prospectNom ?? '').trim().isNotEmpty
        ? prospectNom!.trim()
        : '—';
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory Reparation.fromJson(Map<String, dynamic> m) {
    return Reparation(
      id: '${m['id']}',
      reference: _str(m['reference']),
      panne: '${m['panne'] ?? ''}',
      descriptionProbleme: _str(m['description_probleme']),
      statut: '${m['statut'] ?? ''}',
      clientNom: _str(m['client_nom']),
      prospectNom: _str(m['prospect_nom']),
      technicienNom: _str(m['technicien_nom']),
      typeDiffuseur: _str(m['type_diffuseur']),
      referenceDiffuseur: _str(m['reference_diffuseur']),
    );
  }
}

class ReparationsListResult {
  ReparationsListResult({required this.items, required this.total});

  final List<Reparation> items;
  final int total;

  factory ReparationsListResult.fromJson(Map<String, dynamic> m) {
    final raw = m['items'];
    final items = <Reparation>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(Reparation.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return ReparationsListResult(
      items: items,
      total: (m['total'] as num?)?.toInt() ?? items.length,
    );
  }
}

class RapportMensuelClientSummary {
  RapportMensuelClientSummary({
    required this.clientId,
    required this.clientNom,
    required this.nbInterventions,
    required this.nbAdc,
    required this.nbVdc,
    required this.nbPlanning,
  });

  final String clientId;
  final String clientNom;
  final int nbInterventions;
  final int nbAdc;
  final int nbVdc;
  final int nbPlanning;

  factory RapportMensuelClientSummary.fromJson(Map<String, dynamic> m) {
    return RapportMensuelClientSummary(
      clientId: '${m['client_id'] ?? ''}',
      clientNom: '${m['client_nom'] ?? ''}',
      nbInterventions: (m['nb_interventions'] as num?)?.toInt() ?? 0,
      nbAdc: (m['nb_adc'] as num?)?.toInt() ?? 0,
      nbVdc: (m['nb_vdc'] as num?)?.toInt() ?? 0,
      nbPlanning: (m['nb_planning'] as num?)?.toInt() ?? 0,
    );
  }
}

class RapportMensuelSummary {
  RapportMensuelSummary({
    required this.mois,
    required this.moisLabel,
    required this.clients,
  });

  final String mois;
  final String moisLabel;
  final List<RapportMensuelClientSummary> clients;

  factory RapportMensuelSummary.fromJson(Map<String, dynamic> m) {
    final raw = m['clients'];
    final clients = <RapportMensuelClientSummary>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          clients.add(
            RapportMensuelClientSummary.fromJson(
              Map<String, dynamic>.from(e),
            ),
          );
        }
      }
    }
    return RapportMensuelSummary(
      mois: '${m['mois'] ?? ''}',
      moisLabel: '${m['mois_label'] ?? ''}',
      clients: clients,
    );
  }
}
